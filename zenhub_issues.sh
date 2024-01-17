chmod +x closed_issues.sh
chmod +x other_pipeline_issues.sh
chmod +x github.sh
chmod +x pipeline.sh

rm ./issues_encoded.csv
echo "레포,제목,상태,레이블" > issues.csv
printf '\xEF\xBB\xBF' | cat - issues.csv > issues_encoded.csv

./github.sh