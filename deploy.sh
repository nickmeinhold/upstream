#!/bin/bash
set -e

PROJECT_ID="downstream-181e2"
REGION="us-central1"
SERVICE_NAME="downstream"

echo "=== Downstream Cloud Run Deployment ==="

# Load environment variables from server/.env
if [ -f server/.env ]; then
  echo "Loading environment from server/.env..."
  while IFS= read -r line || [ -n "$line" ]; do
    if [[ -n "$line" && ! "$line" =~ ^# ]]; then
      key="${line%%=*}"
      value="${line#*=}"
      export "$key=$value"
    fi
  done < server/.env
fi

# Verify required env vars
if [ -z "$TMDB_API_KEY" ]; then
  echo "Error: TMDB_API_KEY not set"
  exit 1
fi
if [ -z "$FIREBASE_SERVICE_ACCOUNT" ]; then
  echo "Error: FIREBASE_SERVICE_ACCOUNT not set"
  exit 1
fi

# Step 1: Build Flutter web frontend
echo ""
echo "1. Building Flutter web frontend..."
cd frontend
flutter build web --release --dart-define=dart.vm.product=true
cd ..

# Step 2: Copy web build to server static folder
echo ""
echo "2. Copying web build to server..."
rm -rf server/static
cp -r frontend/build/web server/static

# Step 3: Build Docker image
echo ""
echo "3. Building Docker image..."
cd server
gcloud builds submit --tag gcr.io/$PROJECT_ID/$SERVICE_NAME
cd ..

# Step 4: Deploy to Cloud Run
# Note: Using a secrets file approach for the service account JSON
echo ""
echo "4. Deploying to Cloud Run..."

# Write service account to a temp file for gcloud (handles special chars)
echo "$FIREBASE_SERVICE_ACCOUNT" > /tmp/sa.json

gcloud run deploy $SERVICE_NAME \
  --image gcr.io/$PROJECT_ID/$SERVICE_NAME \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --set-env-vars "TMDB_API_KEY=$TMDB_API_KEY" \
  --set-env-vars "FIREBASE_PROJECT_ID=$PROJECT_ID" \
  --set-env-vars "^@^FIREBASE_SERVICE_ACCOUNT=$(cat /tmp/sa.json)"

rm /tmp/sa.json

echo ""
echo "=== Deployment complete! ==="
gcloud run services describe $SERVICE_NAME --region $REGION --format 'value(status.url)'
