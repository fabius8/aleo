#!/bin/bash

# 定义三个空数组
nums=()
private_keys=()
view_keys=()
addresses=()
transactions=()

# 存储文件路径
filepath="key.txt"

while IFS=' \t' read -r line; do
  arr=($line)
  # 获取行的序号
  num=${arr[0]}

  # 解析列的数量
  case ${#arr[@]} in
    4)
      # 如果有四列，输出第二列、第三列和第四列
      col1=${arr[1]}
      col2=${arr[2]}
      col3=${arr[3]}
      echo "❌ $num $col1 $col2 $col3"
      ;;
    5)
      # 如果有五列，输出第二列、第三列、第四列和第五列
      col1=${arr[1]}
      col2=${arr[2]}
      col3=${arr[3]}
      col4=${arr[4]}
      nums+=("$num")
      private_keys+=("$col1")
      view_keys+=("$col2")
      addresses+=("$col3")
      transactions+=("$col4")
      echo "🍺 $num $col1 $col2 $col3 $col4"
      ;;
    *)
      # 如果有其他数量的列，将其视为错误
      echo "Invalid line: ${line[@]}"
      ;;
  esac
done < $filepath

for ((i=0; i<${#private_keys[@]}; i++))
do
    DIR="thousand_"$i
    echo "第 ${nums[$i]} 个"
    PRIVATEKEY=${private_keys[$i]}
    VIEW_KEY=${view_keys[$i]}
    WALLETADDRESS=${addresses[$i]}
    API_URL=${transactions[$i]}
    echo $PRIVATEKEY
    echo $VIEW_KEY
    echo $WALLETADDRESS
    echo $API_URL

    cd ~
    mkdir $DIR && cd $DIR

    APPNAME=helloworld_"${WALLETADDRESS:4:6}"
    leo new "${APPNAME}"
    cd "${APPNAME}" && leo run && cd -
    PATHTOAPP=$(realpath -q $APPNAME)
    cd $PATHTOAPP && cd ..


    # 检测是否已经安装了 jq
    if ! command -v jq &> /dev/null
    then
        sudo apt-get -y install jq
    else
        echo "jq 已经安装！"
    fi
    res=$(curl -s $API_URL)
    value=$(echo $res | jq '.execution.transitions[0].outputs[0].value' | tr -d '"')
    echo $value
    RECORD=$(snarkos developer decrypt --ciphertext $value --view-key $VIEW_KEY)
    echo $RECORD
    snarkos developer deploy "${APPNAME}.aleo" --private-key "${PRIVATEKEY}" --query "https://vm.aleo.org/api" --path "./${APPNAME}/build/" --broadcast "https://vm.aleo.org/api/testnet3/transaction/broadcast" --fee 600000 --record "${RECORD}"
done