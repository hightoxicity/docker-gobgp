#!/bin/busybox sh

NODE_LABELS_JSONFILE="/labels.json"
GOBGPD_CONF="/gobgpd.conf"
CONF_TYPE="toml"
GOBGP_CONF_TARGET=$(mktemp)

usage()
{
    echo "Parse node labels and run gobgpd"
    echo ""
    echo "./entrypoint.sh"
    echo -e "\t-h --help"
    echo -e "\t--node_labels_jsonfile=$NODE_LABELS_JSONFILE"
    echo -e "\t--gobgpd_conf=$GOBGPD_CONF"
    echo -e "\t--conf_type=${CONF_TYPE}"
    echo -e "\t--conf_target=${GOBGP_CONF_TARGET}"
    echo ""
}

while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h | --help)
            usage
            exit
            ;;
        --node_labels_jsonfile)
            NODE_LABELS_JSONFILE=$VALUE
            ;;
        --gobgpd_conf)
            GOBGPD_CONF=$VALUE
            ;;
        --conf_type)
            CONF_TYPE=$VALUE
            ;;
        --conf_target)
            GOBGP_CONF_TARGET=$VALUE
            ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
    shift
done

if [ ! -f ${GOBGPD_CONF} ]; then
  echo "gobgpd conf (${GOBGPD_CONF}) not found"
  exit 1
fi

if [ "${NODE_LABELS_JSONFILE}" != "" ]; then
  if [ ! -f ${NODE_LABELS_JSONFILE} ]; then
    echo "JSON file (${NODE_LABELS_JSONFILE}) not found"
    exit 1
  fi

  export TORAS=$(cat ${NODE_LABELS_JSONFILE} | /bin/jq -r '.toras')
  export TORPEERIP=$(cat ${NODE_LABELS_JSONFILE} | /bin/jq -r '.torpeerip')
  export TORASEGRESS=$(cat ${NODE_LABELS_JSONFILE} | /bin/jq -r '.torasegress')

  echo "Found TOR peer ASN: ${TORAS}"
  echo "Found TOR peer IP: ${TORPEERIP}"
fi

/bin/envsubst < ${GOBGPD_CONF} > ${GOBGP_CONF_TARGET}
#cat ${GOBGPD_CONF} | while IFS= read line; do eval echo "\"${line}\""; done > ${GOBGP_CONF_TARGET}

echo "We will use following config:"

cat ${GOBGP_CONF_TARGET}

# Replace the config
exec /bin/gobgpd -t ${CONF_TYPE} -f ${GOBGP_CONF_TARGET}
