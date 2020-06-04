ln -s `pwd`/jugdata/assets/images ./jekyll/images

npm run builder

echo Подготовка статического сайта
cd jekyll
bundle exec jekyll build
