# 1️⃣ Builder Stage
FROM maven:3.9.9-eclipse-temurin-21 AS builder
WORKDIR /app

COPY pom.xml .
RUN mvn dependency:go-offline -B

COPY src ./src

# Build jar, now always produces target/app.jar
RUN mvn clean package -DskipTests

# 2️⃣ Runner Stage
FROM eclipse-temurin:21-jre-jammy AS runner
WORKDIR /app

COPY --from=builder /app/target/app.jar /app.jar

EXPOSE 4001
EXPOSE 9001

ENTRYPOINT ["java", "-jar", "app.jar"]