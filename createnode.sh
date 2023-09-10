#!/bin/bash

## DESCRIPTION: 

## AUTHOR: CHITRABALAN M (mchitrabalan@gmail.com)


sudo pkill -9 bootnode
sudo pkill -9 geth
sudo pkill -9 constellation

mkdir Node-Creation && cd Node-Creation
sudo apt-get install libdb-dev libleveldb-dev libsodium-dev zlib1g-dev libtinfo-dev
wget https://gethstore.blob.core.windows.net/builds/geth-alltools-linux-amd64-1.10.15-8be800ff.tar.gz
tar -xvzf geth-alltools-linux-amd64-1.10.15-8be800ff.tar.gz
cp geth-linux-amd64-1.10.15-8be800ff.tar.gz/geth .
cp geth-linux-amd64-1.10.15-8be800ff.tar.gz/bootnode .
wget https://github.com/ConsenSys/constellation/releases/download/v0.3.2/constellation-0.3.2-ubuntu1604.tar.xz
tar -xvzf constellation-0.3.2-ubuntu1604.tar.xz
cp constellation-0.3.2-ubuntu1604.tar.xz/constellation-node .
sudo rm -r constellation-0.3.2-ubuntu1604* geth-alltools-linux-amd64-1.10.15-8be800ff*

PROJECT=$PWD
I=1
NAME=node

echo "Enter the Number of Nodes Required :"
read -p "Required: " NREQ
while true
do
	mkdir "$PROJECT"/"$NAME"-"$I"
	NODE="$PROJECT"/"$NAME"-"$I"/
	echo "$NODE"
	echo "Enter the Password for Node '$I'"
	read -p "Required: " password
	touch "$NODE"/password.txt
	echo $password > "$NODE"/password.txt
	./geth --password "$NODE"/password.txt --datadir "$NODE" account new > "$NODE"/account.log
	sleep 1
	ACCOUNT=`grep "0x" "$NODE"/account.log | cut -d' ' -f8` 
	echo "$ACCOUNT" > "$NODE"/account.txt
	./bootnode --genkey="$NODE"/nodekey 
	./bootnode --nodekey="$NODE"/nodekey > "$NODE"/enode.txt &
	sleep 2 
	echo "$NODE"
	echo "ENODE"
	ENODE=`grep enode "$NODE"/enode.txt | cut -d '@' -f1` 
	echo "$ENODE"
	echo "$ENODE" > "$NODE"/Enode.txt
	sleep 2
	if test $NREQ -eq $I ; then
		break;
		fi
	I=$((I+1))
	sleep 2
	sudo pkill -9 bootnode
	sudo pkill -9 geth
	sudo pkill -9 constellation
done

I=1
NODE="$PROJECT"/"$NAME"-"$I"/
touch "$PROJECT"/genesis.json
GENESIS_ACCOUNT=`cat "$NODE"/account.txt`


echo '{ 
  "alloc": {
    "'$GENESIS_ACCOUNT'": { 
      "balance": "100000000000000000000000000000000000000000000000000"
    }
  },
  "coinbase": "0x0000000000000000000000000000000000000000",
  "config": {
    "homesteadBlock": 0,
    "byzantiumBlock": 0,
    "constantinopleBlock": 0,
    "chainId": 10,
    "eip150Block": 0,
    "eip155Block": 0,
    "eip150Hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
    "eip158Block": 0,
    "maxCodeSizeConfig": [
      {
        "block": 0,
        "size": 128
      }
    ],
    "txnSizeLimit": 128,
    "isQuorum": true
  },
  "difficulty": "0x0",
  "extraData": "0x0000000000000000000000000000000000000000000000000000000000000000",
  "gasLimit": "0xE0000000",
  "mixhash": "0x00000000000000000000000000000000000000647572616c65787365646c6578",
  "nonce": "0x0",
  "parentHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
  "timestamp": "0x00"
}' > genesis.json


#54321
echo "Enter the Number of Network ID :"
read -p "Required: " NID
#NID=54321

#50000
echo "Enter the RAFT Port :"
read -p "Required: " RAFT
#RAFT=50000

#22000
echo "Enter the RPC PORT :"
read -p "Required: " RPC
#RPC=22000

#21000
echo "Enter the PORT  :"
read -p "Required: " PORT
#PORT=21000

#9000
echo "Enter the HTTP PORT :"
read -p "Required: " HTTP
#HTTP=9000

#8550
echo "Enter the WS PORT :"
read -p "Required: " WS
#WS=8550


sudo fuser -k $RAFT/tcp
sudo fuser -k $RPC/tcp
sudo fuser -k $PORT/tcp
sudo fuser -k $HTTP/tcp
sudo fuser -k $WS/tcp


I=1
while true
do
	NODE="$PROJECT"/"$NAME"-"$I"/
	echo "[" > "$NODE"/static-nodes.json
	echo "[" > "$NODE"/permissioned-nodes.json
	tmp=0
	echo "start"
	for value in $(seq 1 $NREQ);
	do
		TPORT=`expr $PORT + $tmp`
		TRAFT=`expr $RAFT + $tmp`
		ENODE=`grep enode "$NAME"-"$value"/enode.txt | cut -d '@' -f1` 
		echo '"'$ENODE'@127.0.0.1:'$TPORT'?discport=0&raftport='$TRAFT'" ' >>  "$NODE"/static-nodes.json
		echo '"'$ENODE'@127.0.0.1:'$TPORT'?discport=0&raftport='$TRAFT'" ' >>  "$NODE"/permissioned-nodes.json
		if test $value -eq $I ; then
			echo "]" >> "$NODE"/static-nodes.json
			echo "]" >> "$NODE"/permissioned-nodes.json
			break;
		else
			echo "," >> "$NODE"/static-nodes.json
			echo "," >> "$NODE"/permissioned-nodes.json
		fi
		tmp=$((tmp+1))
	done
	
	if test $I -eq $NREQ ; then
		break;
	fi
		
	I=$((I+1))
done


I=1
while true 
do 
        NODE="$PROJECT"/"$NAME"-"$I"/
	ACCOUNT=`grep "0x" "$NODE"/account.log | cut -d' ' -f8` 
	ENODE=`grep enode "$NODE"/enode.txt | cut -d '@' -f1`
	echo "Wallet Address :"
	echo $ACCOUNT
	echo "Enode Address :"
	echo $ENODE
	./geth --datadir $NODE init genesis.json
	
	if test $I -eq $NREQ ; then
		break;
	fi
	I=$((I+1)) 
done

I=1
x=0
F=1


constellation="constellation"-$I
start="start"-$I
NODE="$PROJECT"/"$NAME"-"$I"/	
touch "$PROJECT"/$constellation.sh
touch "$PROJECT"/$start.sh

echo 'PROJECT='$PROJECT'' >  "$PROJECT"/$constellation.sh
echo 'PROJECT='$PROJECT'' >  "$PROJECT"/$start.sh
echo 'echo "Enter Key for '$NODE'"' >> "$PROJECT"/$constellation.sh
echo "./constellation-node --generatekeys=$NODE/key" >> "$PROJECT"/$constellation.sh
echo ""2"" >> "$PROJECT"/$constellation.sh
echo './constellation-node --url=https://127.0.0.1:'$HTTP'/ --port='$HTTP' --workdir='$NODE' --socket=constellation_node.ipc --publickeys=key.pub --privatekeys=key.key 				--passwords='$NODE'/password.txt --othernodes=https://127.0.0.1:'$((HTTP+1))'/ 2> '$NODE'/constellation.log &' >> "$PROJECT"/$constellation.sh

echo 'PRIVATE_CONFIG='$NODE'/constellation_node.ipc nohup ./geth --datadir '$NODE' --nodiscover -verbosity 5 --networkid '$NID' --raft --rpccorsdomain "*" --allow-insecure-unlock 			--raftport '$RAFT' --rpc --rpcport '$RPC' --rpcaddr 0.0.0.0 --port '$PORT' --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,raft --emitcheckpoints 			--gcmode=archive --ws 		--wsaddr 0.0.0.0 --wsport '$WS'  --wsorigins "*" --wsapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,raft 2>'$NODE'/node.log 			&' >> 	"$PROJECT"/"$start".sh

I=$((I+1)) 
x=1
while true 	
do
	constellation="constellation"-$I
	start="start"-$I
	NODE="$PROJECT"/"$NAME"-"$I"/	
	touch $NODE
	echo 'PROJECT='$PROJECT'' >  "$PROJECT"/$constellation.sh
	echo 'PROJECT='$PROJECT'' >  "$PROJECT"/$start.sh
	echo 'echo "Enter Key for '$NODE'"' >> "$PROJECT"/$constellation.sh
	echo "./constellation-node --generatekeys=$NODE/key" >> "$PROJECT"/$constellation.sh
	echo "F"
	echo $F
	echo "I"
	echo $I
	echo './constellation-node --url=https://127.0.0.1:'$((HTTP+x))'/ --port='$((HTTP+x))' --workdir='$NODE' --socket=constellation_node.ipc --publickeys=key.pub --privatekeys=key.key 			--passwords='$NODE'/password.txt --othernodes=https://127.0.0.1:'$HTTP'/ 2>'$NODE'/constellation.log &' >> "$PROJECT"/$constellation.sh

	echo 'PRIVATE_CONFIG='$NODE'/constellation_node.ipc nohup ./geth --datadir '$NODE' --nodiscover -verbosity 5 --networkid '$NID' --permissioned --raftjoinexisting '$I' 		         	--raft --rpccorsdomain "*" --allow-insecure-unlock --raftport '$((RAFT+x))' --rpc --rpcport '$((RPC+x))' --rpcaddr 0.0.0.0 --port '$((PORT+x))' --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,raft --emitcheckpoints --gcmode=archive --ws --wsaddr 0.0.0.0                    --wsport '$((WS+x))' --wsorigins "*" --wsapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,raft 2>> '$NODE'/node.log &' >> "$PROJECT"/"$start".sh
		
	
	if test $I -eq $NREQ ; then 
		break
	fi
	
	I=$((I+1)) 
	x=$((x+1)) 
done

I=1
for I in $(seq 1 $NREQ);
do 
	constellation="constellation"-$I
	NODE="$PROJECT"/"$NAME"-"$I"/
	gnome-terminal -x sh -c " sh '$constellation'.sh < "$NODE"/password.txt;bash"
	sleep 6
done

I=1
while true
do
	NODE="$PROJECT"/"$NAME"-"$I"/
	ACCOUNT=`grep "0x" "$NODE"/account.log | cut -d' ' -f8` 
	PASSWORD=`grep . "$NODE"/password.txt`	
	echo $ACCOUNT
	echo $PASSWORD
	echo "personal.unlockAccount('$ACCOUNT','$PASSWORD',0);" > $NODE/unlock.txt
	sleep 6
	if test $I -eq $NREQ ; then
		break;
	fi
	I=$((I+1)) 
done

I=2
X=1
N=1
while true
do
	NODE="$PROJECT"/"$NAME"-"$I"/
	ENODE=`grep enode "$NODE"/Enode.txt | cut -d '@' -f1`
	echo "raft.addPeer('"$ENODE"@127.0.0.1:$((PORT+X))?discport=0&raftport=$((RAFT+X))');" >> $PROJECT/$NAME-$N/unlock.txt 
	echo "admin.sleep(5)" >> $PROJECT/$NAME-$N/unlock.txt 
	sleep 6
	if test $I -eq $NREQ ; then 
		break
	fi
	I=$((I+1))
	X=$((X+1))
done

I=1
while true
do
	NODE="$PROJECT"/"$NAME"-"$I"/
	start="start"-$I
	gnome-terminal -x sh -c " sh $start.sh ;bash"
	sleep 6
	gnome-terminal -x sh -c " ./geth attach $NODE/geth.ipc < $NODE/unlock.txt;bash"
	sleep 6
		if test $I -eq $NREQ ; then 
		break
		fi
	I=$((I+1)) 
done

./geth attach node-1/geth.ipc


