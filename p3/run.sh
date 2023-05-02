#!/bin/bash
# Set the color variable
green='\033[0;32m'
red='\033[0;31m'
# Clear the color after that
clear='\033[0m'

BOXURL="https://app.vagrantup.com/debian/boxes/bullseye64/versions/11.20221219.1/providers/virtualbox.box"
GOINFRE="/opt/goinfre/$USER"
BOXPATH=$GOINFRE"/debian_bullseye64"


if [ -n "$1" -a "$1" == "f" ]; then {
    if test -f "$BOXPATH"; then {
        printf "${green}$BOXPATH exists${clear}\n"
    }
    else {
        printf "${red}$BOXPATH does not found. Download it from $BOXURL${clear}\n"
        exit -1
        # printf "${green}Downloading from $BOXURL to $BOXPATH${clear}\n"
        # curl -o $BOXPATH.downloading $BOXURL &&
        # mv $BOXPATH.downloading $BOXPATH
    }
    fi
    if ! test -d $GOINFRE/.vagrant.d; then {
        printf "${green}$GOINFRE/.vagrant.d not found${clear}\n"
        mkdir $GOINFRE/.vagrant.d
        if test -d $HOME/.vagrant.d; then {
            printf "${green}$HOME/.vagrant.d exists${clear}\n"
            mv $HOME/.vagrant.d/* $GOINFRE/.vagrant.d/
            rm -f $HOME/.vagrant.d
            ln -s $GOINFRE/.vagrant.d $HOME/.vagrant.d
        }
        fi
        if test -d $GOINFRE/.vagrant.d/boxes; then
            mkdir $GOINFRE/.vagrant.d/boxes
        fi
        if test -d $GOINFRE/.vagrant.d/tmp; then
            mkdir $GOINFRE/.vagrant.d/tmp
        fi
    }
    fi
    export VAGRANT_HOME="$HOME/goinfre/.vagrant.d"
    printf "${green}Adding Vagrant box debian_bullseye63${clear}\n"
    vagrant box add debian_bullseye64 ~/goinfre/debian_bullseye64   

    vagrant up

    CAT1=$(cat ~/.ssh/known_hosts)
    SUBSTR=("localhost]:2222" "localhost]:2200")
    LCLHST=$(cat ~/.ssh/known_hosts | grep $SUBSTR)
    for i in "${SUBSTR[@]}"; do
        if [[ $LCLHST == *"$SUBSTR"* ]]; then {
            sed -i.bak "/$SUBSTR/d" ~/.ssh/known_hosts # Удаляем запись если есть
            printf "${green}Из файла ~/.ssh/known_hosts удалена строка содержащая localhost, создан файл бэкапа${clear}\n"
        }
        fi
    done
    printf "${green}Copying yamls to ~/confs${clear}\n"
    scp -r -P 2222 -o StrictHostKeyChecking=no ./confs vagrant@localhost:. 

    printf "${green}Выполняем развертывание${clear}\n"
    ssh -o StrictHostKeyChecking=no -q vagrant@localhost -p 2222 "bash -s" < ./p3.sh
    # ssh -o StrictHostKeyChecking=no -q vagrant@localhost -p 2222 "bash -s" < ./scripts/cluster.sh
}
fi
ssh -o StrictHostKeyChecking=no -q vagrant@localhost -p 2222