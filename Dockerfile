FROM hyperledger/fabric-ca

# Switch to root user to install packages
USER root

# Install wget and create directory
RUN apt-get update && apt-get install -y wget && \
    mkdir -p /usr/local/share && \
    wget https://jdbc.postgresql.org/download/postgresql-42.6.0.jar -O /usr/local/share/postgresql-jdbc.jar

# Switch back to fabric user
USER fabriccauser