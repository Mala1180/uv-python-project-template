#!/usr/bin/env bash

set -uo pipefail

TEMPLATE_PROJECT_NAME="uv-python-project-template"
TEMPLATE_MODULE_NAME="uv_python_project_template"
TEMPLATE_PLACEHOLDER_NAME="my_project"
HAD_ERROR=0

if [[ $# -ne 1 || -z "${1:-}" ]]; then
    echo "Usage: $0 <new-project-name>" 1>&2
    exit 1
fi

PROJECT_NAME=$1

if [[ ! "$PROJECT_NAME" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
    echo "Warning: project name '$PROJECT_NAME' is unusual; continuing with a best-effort rename." 1>&2
fi

MODULE_NAME=$(printf "%s" "$PROJECT_NAME" \
    | tr "[:upper:]" "[:lower:]" \
    | sed -E "s/[-.]+/_/g; s/[^a-z0-9_]/_/g; s/_+/_/g; s/^_+//; s/_+$//")

if [[ -z "$MODULE_NAME" ]]; then
    echo "Warning: could not derive a Python module name from '$PROJECT_NAME'; using '$TEMPLATE_PLACEHOLDER_NAME'." 1>&2
    MODULE_NAME=$TEMPLATE_PLACEHOLDER_NAME
fi

if [[ "$MODULE_NAME" =~ ^[0-9] ]]; then
    MODULE_NAME="_$MODULE_NAME"
fi

if [[ ! "$MODULE_NAME" =~ ^[a-z_][a-z0-9_]*$ ]]; then
    echo "Warning: derived Python module name '$MODULE_NAME' is unusual; continuing." 1>&2
fi

replace_in_file() {
    local file=$1
    local search=$2
    local replacement=$3

    SEARCH=$search REPLACEMENT=$replacement perl -0pi -e 's/\Q$ENV{SEARCH}\E/$ENV{REPLACEMENT}/g' "$file"
}

rename_package_dir() {
    local source_dir="src/$TEMPLATE_MODULE_NAME"
    local target_dir="src/$MODULE_NAME"

    if [[ ! -d "$source_dir" ]]; then
        echo "Warning: expected package directory '$source_dir' does not exist; skipping directory rename." 1>&2
        HAD_ERROR=1
        return
    fi

    if [[ "$source_dir" == "$target_dir" ]]; then
        return
    fi

    if [[ -e "$target_dir" ]]; then
        echo "Warning: target package path '$target_dir' already exists; skipping directory rename." 1>&2
        HAD_ERROR=1
        return
    fi

    if ! mv "$source_dir" "$target_dir"; then
        echo "Warning: could not rename '$source_dir' to '$target_dir'; continuing." 1>&2
        HAD_ERROR=1
    fi
}

mark_update_error() {
    local file=$1

    echo "Warning: could not update '$file'." 1>&2
    HAD_ERROR=1
}

cleanup_backup_files() {
    local file

    while IFS= read -r -d "" file; do
        if ! rm -f -- "$file"; then
            echo "Warning: could not remove backup file '$file'." 1>&2
            HAD_ERROR=1
        fi
    done < <(
        find . \
            \( \
                -path "./.git" -o \
                -path "./.venv" -o \
                -path "./.mypy_cache" -o \
                -path "./.pytest_cache" -o \
                -path "./.ruff_cache" -o \
                -path "./__pycache__" -o \
                -path "./build" -o \
                -path "./dist" -o \
                -path "./htmlcov" \
            \) -prune \
            -o -type f \
            -name "*.bak" \
            -print0
    )
}

while IFS= read -r -d "" file; do
    if [[ "$file" == "./rename-template.sh" ]]; then
        continue
    fi

    replace_in_file "$file" "$TEMPLATE_PROJECT_NAME" "$PROJECT_NAME" || mark_update_error "$file"
    replace_in_file "$file" "$TEMPLATE_MODULE_NAME" "$MODULE_NAME" || mark_update_error "$file"
    replace_in_file "$file" "$TEMPLATE_PLACEHOLDER_NAME" "$MODULE_NAME" || mark_update_error "$file"
done < <(
    find . \
        \( \
            -path "./.git" -o \
            -path "./.venv" -o \
            -path "./.mypy_cache" -o \
            -path "./.pytest_cache" -o \
            -path "./.ruff_cache" -o \
            -path "./__pycache__" -o \
            -path "./build" -o \
            -path "./dist" -o \
            -path "./htmlcov" \
        \) -prune \
        -o -type f \
        -not -name "*.pyc" \
        -not -name "*.pyo" \
        -print0
)

rename_package_dir
cleanup_backup_files

echo "Renamed project to '$PROJECT_NAME' with Python module '$MODULE_NAME'."

if [[ "$HAD_ERROR" -eq 0 ]]; then
    rm -- "$0" || echo "Warning: project was renamed, but '$0' could not be removed." 1>&2
else
    echo "Warning: rename completed with warnings; keeping '$0' for manual cleanup." 1>&2
fi
