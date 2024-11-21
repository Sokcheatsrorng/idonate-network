#install binary into the project

binary option:
    #!/bin/bash
    case {{option}} in
        install)
            echo "Install Binary"
            bash ./installBinary.sh 
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
            docker run -d -p 8000:8000 -p 8888:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:alpine

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
            cd prometheus-grafana
            docker-compose up -d
            ;;
        stop)
            echo "Stop Dashboard"
            cd prometheus-grafana
            docker-compose down -v
            ;;
        *)
            echo "Invalid Option"
            ;;
    esac

