FROM postgres:16

COPY ./create-multiple-databases.sh /docker-entrypoint-initdb.d/create-multiple-databases.sh 
RUN chmod +x  /docker-entrypoint-initdb.d/create-multiple-databases.sh