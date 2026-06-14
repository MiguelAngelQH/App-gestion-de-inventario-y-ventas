# SmartVentas Web Panel — Instrucciones de uso

## Desarrollo local

```bash
npm install        # instalar dependencias
npm run dev        # iniciar servidor de desarrollo en http://localhost:3000
```

## Requisito: Cuenta de Servicio de Firebase

1. Ir a [Firebase Console](https://console.firebase.google.com)
2. Proyecto → Configuración → Cuentas de servicio
3. "Generar nueva clave privada"
4. Guardar el JSON como `service-account.json` en la raíz del proyecto

## Docker (local)

```bash
# Copiar service-account.json a la raíz
docker compose up -d
# Abrir http://localhost:3000
```

## Desplegar a K3s (cuando el cluster esté disponible)

```bash
# 1. Construir la imagen
docker build -t smart-ventas-web .

# 2. Crear secret con la cuenta de servicio
kubectl create secret generic firebase-service-account \
  --from-file=service-account.json=./service-account.json \
  -n 2023205111

# 3. Aplicar deployment + service
kubectl apply -f k8s/deployment.yaml

# 4. Verificar
kubectl get pods -n 2023205111
kubectl get services -n 2023205111
```
