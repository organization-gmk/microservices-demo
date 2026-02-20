FROM maven:3.9.9-eclipse-temurin-21 AS builder

WORKDIR /app

COPY pom.xml .

RUN mvn dependency:go-offline -B

COPY src ./src

mvn clean package -DskipTests -Dsonar.skip=true

FROM eclipse-temurin:21-jre-jammy AS runner

WORKDIR /app

COPY --from=builder /app/target/*-SNAPSHOT.jar /app.jar

EXPOSE 4004

ENTRYPOINT ["java", "-jar", "app.jar"]
