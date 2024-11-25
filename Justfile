#install binary into the project

binary option:
    #!/bin/bash
    case {{option}} in
        install)
            echo "Install Binary"
            bash ./scripts/installBinary.sh 
            ;;
        *)
            echo "Invalid Option"
            ;;
    esac

network option:
    #!/bin/bash
    case {{option}} in 
        create)
            echo "Create Network" 
            bash ./deploy.sh
            
            ;;
        destroy)
            echo "Destroy Network" 
            bash ./clean-all.sh
            ;;
        remove-org)
            echo "Remove Org"
            bash ./add-remove-org.sh remove Org1 Org1 Org1.com Or1 
            ;;    
        
        *)
            echo "Invalid Option"
            ;;
    esac        

dashboard option:
    #!/bin/bash
    case {{option}} in
        start)
            echo "Start Dashboard"
            cd monitoring
            docker compose down -v
            docker compose pull 
            docker compose up -d
            ;;
        stop)
            echo "Stop Dashboard"
            cd monitoring
            docker compose down -v
            ;;
        *)
            echo "Invalid Option"
            ;;
    esac

