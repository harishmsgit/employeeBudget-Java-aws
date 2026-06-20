FROM maven:3.9.8-eclipse-temurin-21 AS build
WORKDIR /app
COPY services/project-service/pom.xml /app/project-service/pom.xml
COPY services/project-service/src /app/project-service/src
RUN mvn -f /app/project-service/pom.xml clean package -DskipTests

FROM eclipse-temurin:21-jre
WORKDIR /opt/app
COPY --from=build /app/project-service/target/project-service-1.0.0.jar app.jar
EXPOSE 8082
ENTRYPOINT ["java", "-jar", "/opt/app/app.jar"]
