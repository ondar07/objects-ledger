

template='{"name":"IDENTITYNAME","mspid":"MSPID","roles":null,"affiliation":"","enrollmentSecret":"","enrollment":{"signingIdentity":"KEYFILE","identity":{"certificate":"CERT"}}}'

# TODO: cmd arguments
identity = "admin1"
mspid = "org1MSP"

# replace some fields of template
template = template.replace("IDENTITYNAME", identity)
template = template.replace("MSPID", mspid)

import sys
if len(sys.argv) != 3:
    print("Usage: ", sys.argv[0], "<cert_path> <destination_file_path>")
    sys.exit(1)

cert = ""
f = open(sys.argv[1], 'r+')
for line in f:
    line = line.replace('\n', '\\n') 
    cert = cert + line
f.close()

# create cert
template = template.replace("CERT", cert)

# save
f = open(sys.argv[2], 'w')
f.write(template)
