#!/bin/bash

# 定义三个空数组
nums=()
private_keys=()
view_keys=()
addresses=()
transactions=()

#export all_proxy=

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
    DIR="thousand_"${nums[$i]}
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
    mkdir -p $DIR && cd $DIR

    APPNAME=helloworld_"${WALLETADDRESS:4:6}"
    leo new "${APPNAME}" >/dev/null
    cd "${APPNAME}" && leo run >/dev/null && cd -
    PATHTOAPP=$(realpath -q $APPNAME)
    cd $PATHTOAPP && cd ..


    # 检测是否已经安装了 jq
    if ! command -v jq &> /dev/null
    then
        sudo apt-get -y install jq
    else
        echo "jq 已经安装！"
    fi
    res=$(curl --connect-timeout 5 --max-time 10 -s $API_URL)
    echo $API_URL
    value=$(echo $res | jq '.execution.transitions[0].outputs[0].value' | tr -d '"')
    echo $value
    RECORD=$(snarkos developer decrypt --ciphertext $value --view-key $VIEW_KEY)
    echo $RECORD

    RESULT=$(snarkos developer deploy "${APPNAME}.aleo" --private-key "${PRIVATEKEY}" --query "https://vm.aleo.org/api" --path "./${APPNAME}/build/" --broadcast "https://vm.aleo.org/api/testnet3/transaction/broadcast" --fee 600000 --record "${RECORD}")
    echo $RESULT
    while [[ $RESULT =~ "state" ]]; do
        # your code here
        echo "Retrying ..."
        sleep 1 # you can adjust the sleep time here
        RESULT=$(snarkos developer deploy "${APPNAME}.aleo" --private-key "${PRIVATEKEY}" --query "https://vm.aleo.org/api" --path "./${APPNAME}/build/" --broadcast "https://vm.aleo.org/api/testnet3/transaction/broadcast" --fee 600000 --record "${RECORD}")
        echo "${RESULT}"
    done 

    sleep 10
    RESULT=$(snarkos developer execute "${APPNAME}.aleo" "main" "1u32" "2u32" --private-key "${PRIVATEKEY}" --query "https://vm.aleo.org/api" --broadcast "https://vm.aleo.org/api/testnet3/transaction/broadcast")
    echo $RESULT
    while [[ $RESULT =~ "status code" ]]; do
        # your code here
        echo "Retrying ..."
        sleep 1 # you can adjust the sleep time here
        RESULT=$(snarkos developer execute "${APPNAME}.aleo" "main" "1u32" "2u32" --private-key "${PRIVATEKEY}" --query "https://vm.aleo.org/api" --broadcast "https://vm.aleo.org/api/testnet3/transaction/broadcast")
        echo "${RESULT}"
    done 
    echo "🍺" ${nums[$i]} $WALLETADDRESS $RESULT>> ~/ok.txt
    sleep 10
done