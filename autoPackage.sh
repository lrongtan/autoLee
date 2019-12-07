
#!/bin/sh

# 符号#!用来告诉系统它后面的参数是用来执行该文件的程序

if [ ! -d ./ipaDir ]
    then
        mkdir -p ipaDir
fi

# chmod +x filename  获取运行脚本文件的权限

project_path=$(cd `dirname $0`; pwd)

#   ${变量名}

echo "获取shell所在路径，即项目路径<<<====>>>"${project_path}

#{
##字符串截取
#OLD_IFS="$IFS"
##分隔符
#IFS="/"
#
#project_path_folders=(${project_path})
#
#IFS="$OLD_IFS"
##数组长度
#folders_length=${#project_path_folders[*]}
#
#path_last_name=${project_path_folders[${folders_length}-1]}
#
#}

path_last_name=${project_path##*/}

echo "获取到名字:" ${path_last_name}

#工程名 - 这里直接将项目路径末尾文件夹名字设置为项目名
project_name=$path_last_name

#
sheme_name=$path_last_name


apple_account="lirongtan0603@sina.com"

apple_password="Lz12345678"

apple_v_password="arjd-isve-rlro-vofg"

#kechain方式保存账号密码
apple_account_keychain="apple_development_account"

apple_account_v_keychain="apple_development_account_v"



#打包模式 Debug/Release
development_mode=Release

#build文件夹路径
build_path=${project_path}/build

if [ -d $build_path ]
    then
        rm -rf $build_path
        echo "删除执行了>>>>>>>>>>>>"
fi


#需要配置 ExportOptions.plist 文件  配置描述文件和证书信息
#plist文件所在路径    {app-store, ad-hoc, enterprise, development, validation} plist文件method的值
exportOptionsPlistPath=${project_path}/ExportOptions.plist

if [ -f $exportOptionsPlistPath ]
    then
        echo "存在exportOptionsPlistPath"
fi

##导出.ipa文件所在路径
#exportIpaPath=${project_path}/ipaDir/${development_mode}

file_paths=$(ls ${project_path})

#是否xcworkspace

is_xcworkspace="0"

for f_path in $file_paths
    do
#    echo "遍历文件路径:" $f_path
        suffix=${f_path##*.}
        if [ ${suffix} == "xcworkspace" ]
            then
            is_xcworkspace="1"
        fi
    
    done

#配置蒲公英账号的信息

pgy_uKey="f5992cb04efa02bd5214bd70684231bc"

pgy_api_key="84643ce64c3c79aab95f1bc227967be1"


#配置fir.im的账号信息
fir_im_key=""

fir_im_token=""

#走什么样的工程 [ad hoc]  [app store]    [development]

#read -p "请输入打包方式  [1. ad hoc]   [2. app store]  [3. development] >> : " package_type

package_type="2"

if [ $package_type == "1" ]

    then
    
    exportOptionsPlistPath=${project_path}/ExportAdHoc.plist
#   fir.im方式没有测试过。要实名太麻烦
    read -p "请选择测试平台  [1. 蒲公英]   [2. fir.im] >> : " test_platform

elif [ $package_type ==  "2" ]
    then
    exportOptionsPlistPath=${project_path}/ExportAppStore.plist
    
elif [ $package_type ==  "3" ]

    then
    
    development_mode=Debug

    exportOptionsPlistPath=${project_path}/ExportDevelopement.plist
    
    read -p "请选择测试平台  [1. 蒲公英]   [2. fir.im] >> : " test_platform

else

    echo "没有这种打包方式"

fi


#导出.ipa文件所在路径
exportIpaPath=${project_path}/ipaDir/${development_mode}

echo "<<<<<<<<<<<<<<<<正在清理工程>>>>>>>>>>>>>>>>>>"

xcodebuild \
clean -configuration ${development_mode} -quiet || exit

echo "<<<<<<<<<<<<<<<<  清理完成  >>>>>>>>>>>>>>>>>>"

echo "<<<<<<<<<<<正在编译工程: ${development_mode}>>>>>>>>>>>"

#xcodebuild \
#   archive -workspace ${project_path}/${project_name}.${is_xcworkspace} \
#   -scheme ${sheme_name} \
#   -configuration ${development_mode} \
#   -archivePath ${build_path}/${project_name}.xcarchive -quiet || exit

#根据是否有无workspace选择编译方式 archive -project与 archive -workspace 的区别

if [ ${is_xcworkspace} == "1" ]
    then
        xcodebuild \
        archive -workspace ${project_path}/${project_name}.xcworkspace \
        -scheme ${sheme_name} \
        -configuration ${development_mode} \
        -archivePath ${build_path}/${project_name}.xcarchive \
        -quiet || exit
    else

        xcodebuild \
        archive -project ${project_path}/${project_name}.xcodeproj \
        -scheme ${sheme_name} \
        -configuration ${development_mode} \
        -archivePath ${build_path}/${project_name}.xcarchive \
        -quiet || exit
fi

echo "<<<<<<<<<<<<<<<<  编译完成  >>>>>>>>>>>>>>>>>>"

echo "<<<<<<<<<<<<<<<<  打包成ipa文件  >>>>>>>>>>>>>>>>>>"

xcodebuild -exportArchive -archivePath ${build_path}/${project_name}.xcarchive \
-configuration ${development_mode} \
-exportPath ${exportIpaPath} \
-exportOptionsPlist ${exportOptionsPlistPath} \
-allowProvisioningUpdates \
-quiet || exit

if [ -d $build_path ]
    then
        rm -rf $build_path
fi

if [ -e $exportIpaPath/$sheme_name.ipa ]
    then
        echo "<<<<<<<<<<<<<<<<  ipa文件已经导出  >>>>>>>>>>>>>>>>>>"
        open $exportIpaPath
        
else
        echo "<<<<<<<<<<<<<<<<  ipa文件已经失败  >>>>>>>>>>>>>>>>>>"
        
        return
fi

echo "<<<<<<<<<<<<<<<<  ipa打包完成  >>>>>>>>>>>>>>>>>>"

echo "<<<<<<<<<<<<<<<<  开始发布ipa包  >>>>>>>>>>>>>>>>>>"


#altoolPath="/Applications/Xcode.app/Contents/Applications/Application Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Versions/A/Support/altool"
#
#"$altoolPath" --validate-app -f ${exportIpaPath}/Apps/${sheme_name}.ipa -u ${apple_account} [-p ${apple_password}]
#
#"$altoolPath" --upload-app -f ${exportIpaPath}/Apps/${sheme_name}.ipa -u ${apple_account} -p ${apple_v_password}

# xcode11 没有默认集成 Application Loader 无法使用上面的方式

if [ $package_type == "1" ]
    then
    
    if [ $test_platform == "1" ]
        then
        curl -F "file=@${exportIpaPath}/${sheme_name}.ipa"\
        -F "uKey=${pgy_uKey}" \
        -F "_api_key=${pgy_api_key}" \
        -F "installType=1"
        https://upload.pgyer.com/apiv1/app/upload
        
    elif [ $test_platform == "2" ]
        then
        curl   -F "key=${fir_im_key}"\
        -F "token=${fir_im_token}" \
        -F "file=@${exportIpaPath}/${sheme_name}.ipa" \
        -F "x:release_type=Adhoc" https://up.qbox.me
    else
        echo "未知平台"
    fi
    
    
    
elif [ $package_type == "2" ]
    then
    
    xcrun altool --validate-app -f ${exportIpaPath}/${sheme_name}.ipa \
    -u ${apple_account} \
    -p @keychain:${apple_account_keychain} \
    --output-format xml

    xcrun altool --upload-app -f ${exportIpaPath}/${sheme_name}.ipa \
    -u ${apple_account} \
    -p @keychain:${apple_account_v_keychain} \
    --output-format xml
    
elif [ $package_type == "3" ]
    then
    
    if [ $test_platform == "1" ]
        then
        curl -F "file=@${exportIpaPath}/${sheme_name}.ipa"\
        -F "uKey=${pgy_uKey}" \
        -F "_api_key=${pgy_api_key}" \
        -F "installType=1" \
        https://upload.pgyer.com/apiv1/app/upload
        
    elif [ $test_platform == "2" ]
        then
        curl   -F "key=${fir_im_key}"\
        -F "token=${fir_im_token}" \
        -F "file=@${exportIpaPath}/${sheme_name}.ipa" \
        -F "x:release_type=Adhoc" https://up.qbox.me
    else
        echo "未知平台"
    fi


else
    echo "没有这种打包方式"

fi

echo "\n"

echo "<<<<<<<<<<<<<<<<           >>>>>>>>>>>>>>>>>>"
echo "<<<<<<<<<<<<<<<<           >>>>>>>>>>>>>>>>>>"
echo "<<<<<<<<<<<<<<<<  success  >>>>>>>>>>>>>>>>>>"
echo "<<<<<<<<<<<<<<<<           >>>>>>>>>>>>>>>>>>"
echo "<<<<<<<<<<<<<<<<           >>>>>>>>>>>>>>>>>>"


exit 0








