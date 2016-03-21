function portopen { 

    netstat -ntpl | grep [0-9]:${1:-8080} -q ; 

    if [ $? -eq 1 ]
    then 
        echo yes 
    else 
        echo no
    fi
}
