#!/usr/bin/env bash

TEMPLATE_PROJECT_NAME="uv-python-project-template"
TEMPLATE_MODULE_NAME="uv_python_project_template"

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
    echo "Warning: could not derive a Python module name from '$PROJECT_NAME'; using '$TEMPLATE_MODULE_NAME'." 1>&2
    MODULE_NAME=$TEMPLATE_MODULE_NAME
fi

if [[ "$MODULE_NAME" =~ ^[0-9] ]]; then
    MODULE_NAME="_$MODULE_NAME"
fi

if [[ ! "$MODULE_NAME" =~ ^[a-z_][a-z0-9_]*$ ]]; then
    echo "Warning: derived Python module name '$MODULE_NAME' is unusual; continuing." 1>&2
fi

for FILE in `find src test -type f  -not -iname '*.pyc' -not -path '*.git*'`; do 
    sed -i '' -e "s/$TEMPLATE_MODULE_NAME/$MODULE_NAME/g" $FILE
done

sed -i '' -e "s/$TEMPLATE_MODULE_NAME/$MODULE_NAME/g" pyproject.toml
sed -i '' -e "s/$TEMPLATE_PROJECT_NAME/$PROJECT_NAME/g" pyproject.toml
sed -i '' -e "s/$TEMPLATE_PROJECT_NAME/$PROJECT_NAME/g" uv.lock

mv "src/$TEMPLATE_MODULE_NAME" "src/$MODULE_NAME"

echo "Renamed project to '$PROJECT_NAME' with Python module '$MODULE_NAME'."