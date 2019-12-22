#!/bin/bash

dataset_name='Dataset_test_1'
total_number=100
lv1_index=10
lv2_index=10
local_dataset_path="/data/${dataset_name}"
regen_img_folder="$HOME/space_center/moon_8K/Regen_Image/"
object="Moon_8K.obj"
git_folder="$HOME/space_center/moon_8K/EVA-Space-Center-Data-Generate"
git pull
# ----------------------------------------------
#rm "../config.py"
cp "config.py"  ".."
cp "generate_dataset.py"  ".."
cp "generate_single_image.py" ".."
# ----------------------------------------------

echo 'Start creating original dataset'
cd "$HOME/space_center/moon_8K/" && python "generate_dataset.py" -o "${object}" -dn "${dataset_name}" -n "${total_number}" -lv1 "${lv1_index}" -lv2 "${lv2_index}"
echo 'End creating original dataset'
# ----------------------------------------------

echo "Start checking original dataset ${dataset_name}"

for i in $(seq 0 "$((lv1_index - 1))")
do
  echo "${i}"
  for j in $(seq 0 "$((lv2_index - 1))")
  do
    for img in "${local_dataset_path}/$i/${i}_$j"/*.png
    do
#      echo "${img}"
      pngcheck -q "${img}"
      retval=$?
      if [ $retval -ne 0 ]; then
        OIFS="$IFS"
        IFS='/'
        read -r -a new_string <<< "${img}"
        IFS="$OIFS"
        python "generate_single_image.py" -o "${object}" -d "${new_string[5]}"
        cp "${img}" "${regen_img_folder}/defect_image"
        cp "${local_dataset_path}/target_$i.json" "${regen_img_folder}/defect_image/target_${i}_${new_string[5]}.json"
        cp "${regen_img_folder}/${new_string[5]}" "${img}"
        cd "${git_folder}" && python "replace_target.py" -d "${new_string[5]}" -i "$i" -o "${object}" -dn "${dataset_name}" -n "${total_number}" -lv1 "${lv1_index}" -lv2 "${lv2_index}"
      fi
    done
  done
done
cd "${git_folder}" && python "compress_file.py" -dn "${dataset_name}" -n "${total_number}" -lv1 "${lv1_index}" -lv2 "${lv2_index}"
echo 'End checking original dataset'
# ----------------------------------------------

# build remote dataset after creat original dataset
local_private_key="$HOME/.ssh/eva_59"
remote_IP='charleschiu@140.113.86.58'
git_folder="$HOME/EVA-Space-Center-Data-Generate"
ssh -i "${local_private_key}" "${remote_IP}"
cd "${git_folder}" || git pull