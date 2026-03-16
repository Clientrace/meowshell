function xy
    set -l derecho_dir /Users/clarence/Dev/derecho

    if not test -d $derecho_dir
        echo "Derecho directory not found: $derecho_dir"
        return 1
    end

    function _xy_branch
        git -C /Users/clarence/Dev/derecho rev-parse --abbrev-ref HEAD 2>/dev/null \
            | tr '[:upper:]' '[:lower:]' \
            | sed 's/[^a-z0-9_-]/-/g'
    end

    function _xy_project
        echo "derecho-"(_xy_branch)
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
        echo "  shell   Open a bash shell in the spearhead container"
        echo "  test    Run backend tests (same as make testsimple)"
        echo "  migrate [app] [rollback_to]  Run migrations"
        echo "  migrations [args]  Create new migrations"
        echo "  lint    Run lintpy and lintjs"
        echo "  clone   Clone volumes from the running environment to current branch"
        echo "  reset   Stop all running environments except current branch"
        return 0
    end

    switch $argv[1]
        case start
            set -l project (_xy_project)
            echo "Starting environment: $project"
            COMPOSE_PROJECT_NAME=$project make -C $derecho_dir start

        case stop
            set -l project (_xy_project)
            echo "Stopping environment: $project"
            COMPOSE_PROJECT_NAME=$project docker compose -f $derecho_dir/docker-compose.yaml stop

        case cur
            set -l project (_xy_project)
            set -l branch (_xy_branch)
            echo "Active environment: $project"
            echo "Branch: $branch"
            echo ""
            COMPOSE_PROJECT_NAME=$project docker compose -f $derecho_dir/docker-compose.yaml ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null
            or echo "No containers running for this environment"

        case list
            echo "Branch environments with Docker volumes:"
            echo "========================================="
            for vol in (docker volume ls --format '{{.Name}}' | grep '_postgres$' | sed 's/_postgres$//' | sort)
                set -l branch (echo $vol | sed 's/^derecho-//')
                set -l running (COMPOSE_PROJECT_NAME=$vol docker compose -f $derecho_dir/docker-compose.yaml ps -q 2>/dev/null | head -1)
                if test -n "$running"
                    echo "  $branch (running)"
                else
                    echo "  $branch"
                end
            end
            echo ""
            echo "Current: "(_xy_project)

        case clear
            if test (count $argv) -lt 2
                echo "Usage: xy clear <branch-name>"
                echo "Run 'xy list' to see available environments"
                return 1
            end
            set -l sanitized (echo $argv[2] | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_-]/-/g')
            set -l project "derecho-$sanitized"
            echo "This will remove all containers and volumes for: $project"
            read -P "Are you sure? (y/N): " confirm
            if test "$confirm" = y; or test "$confirm" = Y
                COMPOSE_PROJECT_NAME=$project docker compose -f $derecho_dir/docker-compose.yaml down --volumes 2>/dev/null
                echo "Cleaned up environment for branch: $sanitized"
            else
                echo "Cancelled"
            end

        case cleardb
            set -l project (_xy_project)
            echo "This will clear the DB and mediafiles for: $project"
            read -P "Are you sure? (y/N): " confirm
            if test "$confirm" = y; or test "$confirm" = Y
                rm -rf $derecho_dir/spearhead/spearhead/mediafiles/
                mkdir -p $derecho_dir/spearhead/spearhead/mediafiles/
                git -C $derecho_dir checkout -- spearhead/spearhead/mediafiles/
                COMPOSE_PROJECT_NAME=$project docker compose -f $derecho_dir/docker-compose.yaml down --volumes
                echo "Cleared DB and mediafiles for: $project"
            else
                echo "Cancelled"
            end

        case loadfixtures
            set -l project (_xy_project)
            echo "Loading fixtures for: $project"
            COMPOSE_PROJECT_NAME=$project docker compose -f $derecho_dir/docker-compose.yaml up -d
            COMPOSE_PROJECT_NAME=$project make -C $derecho_dir migrate
            COMPOSE_PROJECT_NAME=$project docker compose -f $derecho_dir/docker-compose.yaml exec spearhead python manage.py loadfixtures $argv[2..]
            COMPOSE_PROJECT_NAME=$project make -C $derecho_dir savedb

        case test
            set -l project (_xy_project)
            COMPOSE_PROJECT_NAME=$project docker compose -f $derecho_dir/docker-compose.yaml exec -it spearhead python manage.py test --settings=spearhead.settings.tests -- --nomigrations $argv[2..]

        case migrate
            set -l project (_xy_project)
            echo "Running migrations for: $project"
            COMPOSE_PROJECT_NAME=$project docker compose -f $derecho_dir/docker-compose.yaml exec spearhead python manage.py migrate $argv[2..]
            COMPOSE_PROJECT_NAME=$project docker compose -f $derecho_dir/docker-compose.yaml exec spearhead python manage.py migrate --database=usage $argv[2..]
            COMPOSE_PROJECT_NAME=$project docker compose -f $derecho_dir/docker-compose.yaml exec spearhead python manage.py migrate --database=redshift $argv[2..]

        case migrations
            set -l project (_xy_project)
            echo "Creating migrations for: $project"
            COMPOSE_PROJECT_NAME=$project docker compose -f $derecho_dir/docker-compose.yaml exec -it spearhead python manage.py makemigrations $argv[2..]
            COMPOSE_PROJECT_NAME=$project docker compose -f $derecho_dir/docker-compose.yaml exec -T spearhead python -m black .

        case lint
            set -l project (_xy_project)
            echo "Running linters for: $project"
            COMPOSE_PROJECT_NAME=$project make -C $derecho_dir lintpy
            COMPOSE_PROJECT_NAME=$project make -C $derecho_dir lintjs

        case clone
            set -l target_project (_xy_project)
            set -l compose_file $derecho_dir/docker-compose.yaml

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
            set -l current_project (_xy_project)
            set -l compose_file $derecho_dir/docker-compose.yaml
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
            set -l project (_xy_project)
            COMPOSE_PROJECT_NAME=$project docker compose -f $derecho_dir/docker-compose.yaml exec -it spearhead bash

        case '*'
            echo "Unknown command: $argv[1]"
            echo "Run 'xy' for usage"
            return 1
    end
end
