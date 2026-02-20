# 1️⃣ Builder Stage
FROM maven:3.9.9-eclipse-temurin-21 AS builder
WORKDIR /app

COPY pom.xml .
RUN mvn dependency:go-offline -B

COPY src ./src

# Build and repackage Spring Boot jar
mvn clean package -DskipTests -Dsonar.skip=true

# 2️⃣ Runner Stage
FROM eclipse-temurin:21-jre-jammy AS runner
WORKDIR /app

# Copy the **Spring Boot repackaged JAR**
COPY --from=builder /app/target/*-SNAPSHOT.jar /app.jar

EXPOSE 4001
EXPOSE 9001

ENTRYPOINT ["java", "-jar", "app.jar"]