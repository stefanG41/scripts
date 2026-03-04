echo "=== Stack Versions ==="

echo "Kubernetes (client) .: $(kubectl version | awk -F': ' '/Client Version/{print $2}' | head -n1)"
echo "Kubernetes (server) .: $(kubectl version | awk -F': ' '/Server Version/{print $2}' | head -n1)"
echo "Helm ...............: $(helm version --short | cut -d '+' -f1 | sed 's/v//')"

# Charts (wenn Release existiert)
echo "Longhorn Chart ......: $(helm -n longhorn-system list -o json 2>/dev/null | jq -r '.[] | select(.name=="longhorn") | .chart' || true)"
echo "MetalLB Chart .......: $(helm -n metallb-system list -o json 2>/dev/null | jq -r '.[] | select(.name=="metallb") | .chart' || true)"

# Flannel (wenn DS existiert)
FLANNEL_IMG=$(kubectl -n kube-flannel get ds kube-flannel-ds -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || true)
if [ -n "$FLANNEL_IMG" ]; then
  echo "Flannel .............: ${FLANNEL_IMG##*:}"
else
  echo "Flannel .............: (not found)"
fi

# metrics-server (häufig: kube-system, Name kann variieren)
METRICS_IMG=$(kubectl -n kube-system get deploy -l k8s-app=metrics-server -o jsonpath='{.items[0].spec.template.spec.containers[0].image}' 2>/dev/null || true)
if [ -n "$METRICS_IMG" ]; then
  echo "metrics-server ......: ${METRICS_IMG##*:}"
else
  # fallback: any deploy name containing metrics-server
  METRICS_IMG=$(kubectl -n kube-system get deploy -o json | jq -r '.items[] | select(.metadata.name|test("metrics-server")) | .spec.template.spec.containers[0].image' 2>/dev/null | head -n1)
  if [ -n "$METRICS_IMG" ]; then
    echo "metrics-server ......: ${METRICS_IMG##*:}"
  else
    echo "metrics-server ......: (not installed)"
  fi
fi

# ingress-nginx (kann namespace/name abweichen)
ING_NS=$(kubectl get ns -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | grep -E '^ingress-nginx$|^ingress$|^nginx-ingress$' | head -n1)
if [ -n "$ING_NS" ]; then
  INGRESS_IMG=$(kubectl -n "$ING_NS" get deploy -o json | jq -r '.items[] | select(.metadata.name|test("controller|ingress-nginx|nginx-ingress")) | .spec.template.spec.containers[0].image' | head -n1)
  if [ -n "$INGRESS_IMG" ]; then
    echo "ingress-nginx .......: ${INGRESS_IMG##*:}"
  else
    echo "ingress-nginx .......: (namespace $ING_NS, controller not found)"
  fi
else
  echo "ingress-nginx .......: (not installed)"
fi
