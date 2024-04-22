We'll break down your requirements into three main parts: setting up the `traccar-server` with customized configuration, configuring the `mysql` database, and creating a Docker container for the `traccar-web` application using `nginx`. Finally, we'll stitch everything together in a `docker-compose.yml` file.

### 1. traccar-server Configuration

**Docker Volume for traccar-server**:
We'll create a volume to store the `traccar.xml` configuration so that it persists across container restarts.

**traccar.xml**:
Here’s an example of a basic `traccar.xml`. You would adjust this according to your specific requirements:
```xml
<?xml version='1.0' encoding='UTF-8'?>

<!DOCTYPE properties SYSTEM 'http://java.sun.com/dtd/properties.dtd'>

<properties>

    <entry key='config.default'>./conf/default.xml</entry>
    <entry key='database.driver'>com.mysql.cj.jdbc.Driver</entry>
    <entry key='database.url'>jdbc:mysql://db:3306/traccar?serverTimezone=UTC&amp;useSSL=true&amp;allowMultiQueries=true&amp;autoReconnect=true&amp;useUnicode=yes&amp;characterEncoding=UTF-8&amp;sessionVariables=sql_mode=''</entry>
    <entry key='database.user'>traccar</entry>
    <entry key='database.password'>Traccar.110</entry>

</properties>

```

Replace the placeholders [HOST], [DATABASE], [USER], and [PASSWORD] with your actual MySQL database details:

* [HOST]: The hostname or IP address of your MySQL server (e.g., localhost or a remote server).
* [DATABASE]: The name of the MySQL database where Traccar data will be stored.
* [USER]: Your MySQL username.
* [PASSWORD]: Your MySQL password.

Make sure you have created the database in MySQL and granted necessary permissions to the specified user. Also, ensure that the MySQL server is running and accessible from your Traccar server.

### 2. MySQL Database Configuration

**Docker Volume for MySQL**:
To ensure data persistence, we will use a Docker volume for storing the MySQL database files.

### 3. traccar-web Dockerfile

**Building the React Application**:
We'll use `nginx` as the base image to serve the static content generated from the React build. Here’s how your `Dockerfile` might look:
```Dockerfile
# Build stage
FROM node:18 as build-stage
WORKDIR /app
COPY package*.json ./
RUN npm install --legacy-peer-deps
COPY ./ ./
RUN npm run build

# Production stage
FROM nginx:stable-alpine
COPY --from=build-stage /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
# make sure to expose a proper port
EXPOSE 3000
CMD ["nginx", "-g", "daemon off;"]
```

You would need an `nginx.conf` tailored for serving the React build, which generally looks like:
```nginx
server {
    # make sure you are listening to the right port
    listen       80;
    server_name  localhost;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
        try_files $uri /index.html;
    }

    error_page 500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}
```

### 4. docker-compose.yml

Finally, let’s put everything together in the `docker-compose.yml`.
```yaml
version: '3'
services:
  traccar:
    image: traccar/traccar:latest
    container_name: traccar
    restart: always
    volumes:
      - ./traccar-server-volume/conf/traccar.xml:/opt/traccar/conf/traccar.xml:ro
      - ./traccar-server-volume/logs:/opt/traccar/logs:rw
    ports:
      - "5000-5150:5000-5150"
      - "8082:8082"
    environment:
      - MYSQL_DATABASE=traccar
      - MYSQL_USER=traccar
      - MYSQL_PASSWORD=mypw

  db:
    image: mysql:8.0.20
    container_name: db
    command: --default-authentication-plugin=mysql_native_password
    restart: always
    volumes:
      - ./mysql-volume/data:/var/lib/mysql
      - ./mysql-volume/conf:/etc/mysql/conf.d
    ports:
      - "3306:3306"
    environment:
      - MYSQL_ROOT_PASSWORD=Adnan.110

  traccar-web:
    build:
      context: ./traccar-web  # Path to your Traccar Web app source code
      dockerfile: Dockerfile
    container_name: traccar-web
    restart: always
    ports:
      - "8088:8082"
```

### Additional Notes:
- **Context**: Set your files correctly in designated directories. For instance, you should have `traccar-web` directory with appropriate `Dockerfile` and `nginx.conf` placed correctly.
- **traccar.xml**: Adjust based on your configuration needs.
- **Database**: Make sure the database credentials and ports do not conflict and are correctly set up for security in production.

The above `docker-compose.yml` should help you run your set of services with the necessary persisting volumes and configurations. Adjust as needed based on the scalability and environment-specific needs.
