#!/bin/sh
set -e
COMPRESSION=GZ
# Small script to setup the HBase tables used by OpenTSDB.
test -n "$HBASE_PREFIX" || {
    echo >&2 'The environment variable HBASE_PREFIX must be set'
    exit 1
}
test -d "$HBASE_PREFIX" || {
    echo >&2 "No such directory: HBASE_PREFIX=$HBASE_PREFIX"
    exit 1
}
cp /tmp/hbase-config/* $HBASE_PREFIX/conf/

TSDB_TABLE=${TSDB_TABLE-'tsdb'}
UID_TABLE=${UID_TABLE-'tsdb-uid'}
TREE_TABLE=${TREE_TABLE-'tsdb-tree'}
META_TABLE=${META_TABLE-'tsdb-meta'}
BLOOMFILTER=${BLOOMFILTER-'ROW'}
# LZO requires lzo2 64bit to be installed + the hadoop-gpl-compression jar.
COMPRESSION=${COMPRESSION-'LZO'}
# All compression codec names are upper case (NONE, LZO, SNAPPY, etc).
COMPRESSION=`echo "$COMPRESSION" | tr a-z A-Z`

case $COMPRESSION in
    (NONE|LZO|GZIP|SNAPPY)  :;;  # Known good.
    (*)
    echo >&2 "warning: compression codec '$COMPRESSION' might not be supported."
    ;;
esac
echo "checking if opentsdb $UID_TABLE hbase table exists"
ret=$( echo "exists '$UID_TABLE'" | $HBASE_PREFIX/bin/hbase shell -n )
if [[ $ret == *"true"* ]];
then
    echo "OpenTSDB tables already created."
    exit 0
else
    echo "Creating OpenTSDB hbase tables:"
    $HBASE_PREFIX/bin/hbase shell -n << EOF
    create '$UID_TABLE',
    {NAME => 'id', COMPRESSION => '$COMPRESSION', BLOOMFILTER => '$BLOOMFILTER'},
    {NAME => 'name', COMPRESSION => '$COMPRESSION', BLOOMFILTER => '$BLOOMFILTER'}

    create '$TSDB_TABLE',
    {NAME => 't', VERSIONS => 1, COMPRESSION => '$COMPRESSION', BLOOMFILTER => '$BLOOMFILTER'}

    create '$TREE_TABLE',
    {NAME => 't', VERSIONS => 1, COMPRESSION => '$COMPRESSION', BLOOMFILTER => '$BLOOMFILTER'}

    create '$META_TABLE',
    {NAME => 'name', COMPRESSION => '$COMPRESSION', BLOOMFILTER => '$BLOOMFILTER'}
EOF
echo "DONE"
fi