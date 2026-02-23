FROM maven:3.9.9-eclipse-temurin-21 AS builder

WORKDIR /app

COPY pom.xml .

RUN mvn dependency:go-offline -B

COPY src ./src

RUN mvn clean package -DskipTests -Dsonar.skip=true

FROM eclipse-temurin:21-jre-alpine AS runner

WORKDIR /app

COPY --from=builder /app/target/*-SNAPSHOT.jar app.jar

EXPOSE 4004

ENTRYPOINT ["java", "-jar", "app.jar"]
