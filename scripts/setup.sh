function warnMissingData {
    IS_VALID=0
    echo "Please enter the directory path you want to set up"

    while [ "$IS_VALID" == "0" ]; do
        printf "Path: "
        read NEW_DATA_ROOT
        if [ -d "$NEW_DATA_ROOT" ]; then
            IS_VALID=1
            continue;
        fi
        echo "Please make sure the directory path is valid and exists"
    done

    echo "DATA_ROOT=$NEW_DATA_ROOT" >> "$CONFIG_ROOT/config.sh"
}

function setup {
    bash $SCRIPTPATH/scripts/prerequisites.sh
    warnMissingData
}
