rm -r -f target
mkdir -p target

cp ./jugdata/descriptions/*.yml ./target -r

echo Копирование изображений
cp ./jugdata/assets/images ./jekyll -r

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

echo Подготовка json-файлов с нужной иерархией
docker run --rm -v $(pwd):/documents/ lihame/course-doc \
  nunjucks src/njk/talk2id.njk target/talks.json -p . -e json -o target
cp target/src/njk/talk2id.json ./target/talks-by-id.json;

docker run --rm -v $(pwd):/documents/ lihame/course-doc \
  nunjucks src/njk/author2id.njk target/speakers.json -p . -e json -o target
cp target/src/njk/author2id.json ./target/speakers-by-id.json;

docker run --rm -v $(pwd):/documents/ lihame/course-doc \
  nunjucks src/njk/ev_type2id.njk target/event-types.json -p . -e json -o target
cp target/src/njk/ev_type2id.json ./target/ev_types-by-id.json;

docker run --rm -v $(pwd):/documents/ lihame/course-doc \
  nunjucks src/njk/ev_type2ev.njk ./target/events.json -p . -e json -o target
cp target/src/njk/ev_type2ev.json ./target/ev_type2ev.json;

docker run --rm -v $(pwd):/documents/ lihame/course-doc \
  jq -s '.[0] * .[1] * .[2] * .[3]' target/ev_types-by-id.json target/speakers-by-id.json \
  target/talks-by-id.json target/ev_type2ev.json >target/combined.json

echo Сборка
docker run --env output_lang=en --rm -v $(pwd):/documents/ lihame/course-doc \
  nunjucks src/njk/talks.njk ./target/combined.json -p . -e adoc -o target
cp target/src/njk/talks.adoc ./jekyll/talks_pre_en.adoc;

docker run --env output_lang=ru --rm -v $(pwd):/documents/ lihame/course-doc \
  nunjucks src/njk/talks.njk ./target/combined.json -p . -e adoc -o target
cp target/src/njk/talks.adoc ./jekyll/talks_pre_ru.adoc;

echo Подготовка статического сайта
cd jekyll
bundle exec jekyll build
