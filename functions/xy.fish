function xy
    set -l config_file (status dirname)/../setup.config

    if not test -f $config_file
        echo "Config not found: $config_file"
        echo "Copy setup.config.example to setup.config and fill in your values."
        return 1
    end

    # Read config
    set -l project_dir (grep '^PROJECT_DIR=' $config_file | sed 's/^PROJECT_DIR=//')
    set -l project_name (grep '^PROJECT_NAME=' $config_file | sed 's/^PROJECT_NAME=//')
    set -l service_name (grep '^SERVICE_NAME=' $config_file | sed 's/^SERVICE_NAME=//')
    set -l mediafiles_path (grep '^MEDIAFILES_PATH=' $config_file | sed 's/^MEDIAFILES_PATH=//')
    set -l test_settings (grep '^TEST_SETTINGS=' $config_file | sed 's/^TEST_SETTINGS=//')
    set -l extra_databases (grep '^EXTRA_DATABASES=' $config_file | sed 's/^EXTRA_DATABASES=//' | string split ' ')

    if not test -d $project_dir
        echo "Project directory not found: $project_dir"
        return 1
    end

    function _xy_branch --argument-names project_dir
        git -C $project_dir rev-parse --abbrev-ref HEAD 2>/dev/null \
            | tr '[:upper:]' '[:lower:]' \
            | sed 's/[^a-z0-9_-]/-/g'
    end

    function _xy_project --argument-names project_dir project_name
        echo "$project_name-"(_xy_branch $project_dir)
    end

    if test (count $argv) -eq 0
        echo "Usage: xy <command>"
        echo ""
        echo "Commands:"
        echo "  start   Start containers for current branch"
        echo "  stop    Stop containers for current branch"
        echo "  cur     Show current environment status"
        echo "  list    List all branch environments"
        echo "  clear   Clean up volumes for a branch"
        echo "  cleardb Clear DB and mediafiles for current branch"
        echo "  loadfixtures [sellers]  Load fixtures (optionally specify sellers)"
        echo "  shell   Open a bash shell in the $service_name container"
        echo "  test    Run backend tests"
        echo "  migrate [app] [rollback_to]  Run migrations"
        echo "  migrations [args]  Create new migrations"
        echo "  lint    Run lintpy and lintjs"
        echo "  clone   Clone volumes from the running environment to current branch"
        echo "  reset   Stop all running environments except current branch"
        return 0
    end

    set -l compose_file $project_dir/docker-compose.yaml

    switch $argv[1]
        case start
            set -l project (_xy_project $project_dir $project_name)
            echo "Starting environment: $project"
            COMPOSE_PROJECT_NAME=$project make -C $project_dir start

        case stop
            set -l project (_xy_project $project_dir $project_name)
            echo "Stopping environment: $project"
            COMPOSE_PROJECT_NAME=$project docker compose -f $compose_file stop

        case cur
            set -l project (_xy_project $project_dir $project_name)
            set -l branch (_xy_branch $project_dir)
            echo "Active environment: $project"
            echo "Branch: $branch"
            echo ""
            COMPOSE_PROJECT_NAME=$project docker compose -f $compose_file ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null
            or echo "No containers running for this environment"

        case list
            echo "Branch environments with Docker volumes:"
            echo "========================================="
            for vol in (docker volume ls --format '{{.Name}}' | grep '_postgres$' | sed 's/_postgres$//' | sort)
                set -l branch (echo $vol | sed "s/^$project_name-//")
                set -l running (COMPOSE_PROJECT_NAME=$vol docker compose -f $compose_file ps -q 2>/dev/null | head -1)
                if test -n "$running"
                    echo "  $branch (running)"
                else
                    echo "  $branch"
                end
            end
            echo ""
            echo "Current: "(_xy_project $project_dir $project_name)

        case clear
            if test (count $argv) -lt 2
                echo "Usage: xy clear <branch-name>"
                echo "Run 'xy list' to see available environments"
                return 1
            end
            set -l sanitized (echo $argv[2] | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_-]/-/g')
            set -l project "$project_name-$sanitized"
            echo "This will remove all containers and volumes for: $project"
            read -P "Are you sure? (y/N): " confirm
            if test "$confirm" = y; or test "$confirm" = Y
                COMPOSE_PROJECT_NAME=$project docker compose -f $compose_file down --volumes 2>/dev/null
                echo "Cleaned up environment for branch: $sanitized"
            else
                echo "Cancelled"
            end

        case cleardb
            set -l project (_xy_project $project_dir $project_name)
            echo "This will clear the DB and mediafiles for: $project"
            read -P "Are you sure? (y/N): " confirm
            if test "$confirm" = y; or test "$confirm" = Y
                rm -rf $project_dir/$mediafiles_path/
                mkdir -p $project_dir/$mediafiles_path/
                git -C $project_dir checkout -- $mediafiles_path/
                COMPOSE_PROJECT_NAME=$project docker compose -f $compose_file down --volumes
                echo "Cleared DB and mediafiles for: $project"
            else
                echo "Cancelled"
            end

        case loadfixtures
            set -l project (_xy_project $project_dir $project_name)
            echo "Loading fixtures for: $project"
            COMPOSE_PROJECT_NAME=$project docker compose -f $compose_file up -d
            COMPOSE_PROJECT_NAME=$project make -C $project_dir migrate
            COMPOSE_PROJECT_NAME=$project docker compose -f $compose_file exec $service_name python manage.py loadfixtures $argv[2..]
            COMPOSE_PROJECT_NAME=$project make -C $project_dir savedb

        case test
            set -l project (_xy_project $project_dir $project_name)
            COMPOSE_PROJECT_NAME=$project docker compose -f $compose_file exec -it $service_name python manage.py test --settings=$test_settings -- --nomigrations $argv[2..]

        case migrate
            set -l project (_xy_project $project_dir $project_name)
            echo "Running migrations for: $project"
            COMPOSE_PROJECT_NAME=$project docker compose -f $compose_file exec $service_name python manage.py migrate $argv[2..]
            for db in $extra_databases
                COMPOSE_PROJECT_NAME=$project docker compose -f $compose_file exec $service_name python manage.py migrate --database=$db $argv[2..]
            end

        case migrations
            set -l project (_xy_project $project_dir $project_name)
            echo "Creating migrations for: $project"
            COMPOSE_PROJECT_NAME=$project docker compose -f $compose_file exec -it $service_name python manage.py makemigrations $argv[2..]
            COMPOSE_PROJECT_NAME=$project docker compose -f $compose_file exec -T $service_name python -m black .

        case lint
            set -l project (_xy_project $project_dir $project_name)
            echo "Running linters for: $project"
            COMPOSE_PROJECT_NAME=$project make -C $project_dir lintpy
            COMPOSE_PROJECT_NAME=$project make -C $project_dir lintjs

        case clone
            set -l target_project (_xy_project $project_dir $project_name)

            # Find running environments
            set -l running_projects
            for vol in (docker volume ls --format '{{.Name}}' | grep '_postgres$' | sed 's/_postgres$//' | sort)
                set -l running (COMPOSE_PROJECT_NAME=$vol docker compose -f $compose_file ps -q 2>/dev/null | head -1)
                if test -n "$running"
                    set -a running_projects $vol
                end
            end

            if test (count $running_projects) -eq 0
                echo "No running environment found."
                return 1
            end

            if test (count $running_projects) -gt 1
                echo "Multiple running instances:"
                for p in $running_projects
                    echo "  $p"
                end
                return 1
            end

            set -l source_project $running_projects[1]

            if test "$source_project" = "$target_project"
                echo "Source and target are the same: $source_project"
                return 1
            end

            echo "Cloning: $source_project → $target_project"

            # Verify source volumes exist
            for suffix in postgres timescale redshift
                if not docker volume inspect {$source_project}_{$suffix} >/dev/null 2>&1
                    echo "Source volume not found: {$source_project}_{$suffix}"
                    return 1
                end
            end

            # Stop target if running
            COMPOSE_PROJECT_NAME=$target_project docker compose -f $compose_file stop 2>/dev/null

            # Clone each volume
            for suffix in postgres timescale redshift
                set -l src {$source_project}_{$suffix}
                set -l dst {$target_project}_{$suffix}
                echo "  Cloning volume: $src → $dst"
                docker volume create $dst >/dev/null 2>&1
                docker run --rm -v $src:/src:ro -v $dst:/dst alpine sh -c 'cd /src && tar cf - . | (cd /dst && tar xf -)'
                or begin
                    echo "  Failed to clone volume: $src"
                    return 1
                end
            end

            echo "Volumes cloned for: $target_project"
            echo "Run 'xy start' to start the environment (stop the source first to free ports)."

        case reset
            set -l current_project (_xy_project $project_dir $project_name)
            set -l stopped 0

            for vol in (docker volume ls --format '{{.Name}}' | grep '_postgres$' | sed 's/_postgres$//' | sort)
                if test "$vol" = "$current_project"
                    continue
                end
                set -l running (COMPOSE_PROJECT_NAME=$vol docker compose -f $compose_file ps -q 2>/dev/null | head -1)
                if test -n "$running"
                    echo "Stopping: $vol"
                    COMPOSE_PROJECT_NAME=$vol docker compose -f $compose_file stop
                    set stopped (math $stopped + 1)
                end
            end

            if test $stopped -eq 0
                echo "No other running environments to stop."
            else
                echo "Stopped $stopped environment(s). Current branch ($current_project) left untouched."
            end

        case shell
            set -l project (_xy_project $project_dir $project_name)
            COMPOSE_PROJECT_NAME=$project docker compose -f $compose_file exec -it $service_name bash

        case '*'
            echo "Unknown command: $argv[1]"
            echo "Run 'xy' for usage"
            return 1
    end
end
