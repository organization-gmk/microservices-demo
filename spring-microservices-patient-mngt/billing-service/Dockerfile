# 1️⃣ Build Stage
FROM maven:3.9.9-eclipse-temurin-21 AS builder
WORKDIR /app

# Copy only pom.xml first to cache dependencies
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Build jar with consistent name
RUN mvn clean package -DskipTests \
    && cp target/*.jar /app/app.jar

# 2️⃣ Runtime Stage
FROM eclipse-temurin:21-jre-jammy AS runner
WORKDIR /app

# Copy the jar from builder stage
COPY --from=builder /app/app.jar /app.jar

# Expose service ports
EXPOSE 4001
EXPOSE 9001

# Run the jar
ENTRYPOINT ["java", "-jar", "app.jar"]