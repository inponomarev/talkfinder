rm -r -f target
mkdir -p target
cp ./src/adoc/* ./target -r
cp ./jugdata/descriptions/*.yml ./target -r
echo Копирование изображений
cp ./jugdata/assets/images ./target -r

echo Генерация json-файлов
cd target
find . -type f -name '*.yml' -exec  sh -c \
  $'for f; \
    do 
      echo "$f" && 
      docker run --rm -v $(pwd):/documents/ lihame/course-doc ruby -rjson -ryaml -e \
      "puts JSON.pretty_generate(YAML.load_file(\'"$f"\'))" > "${f%.yml}".json; 
  done' \
  sh {}  +

cd ..
# Подготовка json-файлов с нужной иерархией
docker run --rm -v $(pwd):/documents/ lihame/course-doc \
  nunjucks src/njk/talk2id.njk target/talks.json -p . -e json -o target
mv target/src/njk/talk2id.json ./target/talks-by-id.json;

docker run --rm -v $(pwd):/documents/ lihame/course-doc \
  nunjucks src/njk/author2id.njk target/speakers.json -p . -e json -o target
mv target/src/njk/author2id.json ./target/speakers-by-id.json;

docker run --rm -v $(pwd):/documents/ lihame/course-doc \
  nunjucks src/njk/ev_type2id.njk target/event-types.json -p . -e json -o target
mv target/src/njk/ev_type2id.json ./target/ev_types-by-id.json;

docker run --rm -v $(pwd):/documents/ lihame/course-doc \
  nunjucks src/njk/ev_type2ev.njk ./target/events.json -p . -e json -o target
mv target/src/njk/ev_type2ev.json ./target/ev_type2ev.json;

docker run --rm -v $(pwd):/documents/ lihame/course-doc \
  jq -s '.[0] * .[1] * .[2] * .[3]' target/ev_types-by-id.json target/speakers-by-id.json \
  target/talks-by-id.json target/ev_type2ev.json >target/combined.json

# Сборка
docker run --rm -v $(pwd):/documents/ lihame/course-doc \
  nunjucks src/njk/talks.njk ./target/combined.json -p . -e adoc -o target
mv target/src/njk/talks.adoc ./target/talks_pre.adoc;

docker run --rm -v $(pwd):/documents/ lihame/course-doc \
  asciidoctor -r ./src/extensions/feat-1338.rb \
  -r ./src/extensions/multirow-table-head-tree-processor.rb \
  -v -w ./target/talks.adoc

# Подготовка статического сайта

rm -r -f out
mkdir out
cp target/talks.html out
cp target/images out -r
