
network option:
    #!/bin/bash
    case {{option}} in 
        "create")
            echo "Create Network" 
            bash ./deploy.sh
            ;;
        "destroy")
            echo "Destroy Network" 
            bash ./clean-all.sh
            ;;
    esac        