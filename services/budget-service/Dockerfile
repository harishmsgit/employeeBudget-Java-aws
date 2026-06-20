FROM maven:3.9.8-eclipse-temurin-21 AS build
WORKDIR /app
COPY services/budget-service/pom.xml /app/budget-service/pom.xml
COPY services/budget-service/src /app/budget-service/src
RUN mvn -f /app/budget-service/pom.xml clean package -DskipTests

FROM eclipse-temurin:21-jre
WORKDIR /opt/app
COPY --from=build /app/budget-service/target/budget-service-1.0.0.jar app.jar
EXPOSE 8083
ENTRYPOINT ["java", "-jar", "/opt/app/app.jar"]
