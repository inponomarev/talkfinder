const { readFileSync, writeFileSync } = require('fs');
const { resolve, basename, dirname } = require('path');
const nunjucks = require('nunjucks');
const chalk = require('chalk').default;
const yaml = require('js-yaml');

console.log('Подготовка json-файлов с нужной иерархией');

const inputDir = resolve(process.cwd(), './src/njk') || '';

const nunjucksEnv = nunjucks.configure(inputDir, { trimBlocks: true, lstripBlocks: true, noCache: true });
nunjucksEnv.addFilter('md2asciidoc', function (a) {
  a = a.replace(/C\+\+/g, '{cpp}');
  a = a.replace(/С\+\+/g, '{cpp}');
  a = a.replace(/\&nbsp\;/g, '\xA0');
  a = a.replace(/\&amp\;/g, '&');
  a = a.replace(/\&gt\;/g, '>');
  a = a.replace(/\&lt\;/g, '<');
  a = a.replace(/[ ]+[\n]/g, '\n');
  a = a.replace(/<a[ ]*[^\n]*href="([^\n]*)"[^\n]*target[^\n]*>([^\n]*)<\/a>/g, 'link:\$1[\$2]');
  a = a.replace(/([^\n^>])[\n]([^\n^>])/g, '\$1tyutyutyu\$2');
  a = a.replace(/^[>][\ ]*([a-zA-Zа-яА-Я0-9\ё\_\:\xA0\ \(\)\*\.\'\`\$\&\%\#\@\[\]\{\}\|\;\-\+\—\–\,\«\»\?\/\\\!]*)/gm, '\n====\n\$1\n====\n');
  a = a.replace(/([*][^*]+)tyutyutyu([^*]+[*])/gm, '\$1*tyutyutyu*\$2');
  a = a.replace(/tyutyutyu/g, '\n\n');
  a = a.replace(/====[\n]*====/g, '');
  //  a = a.replace(/(\n[^>][^\n]*)\n>/g, '\1\n====\n' );
  //  a = a.replace(/^[>]/gm, 'TIP: ' );
  return a;
});

nunjucksEnv.addFilter('ansiToGerman', function (dateValue) {
  if ((dateValue == null) || (dateValue === "")) {
    return "—"
  }
  let day = dateValue.split("-")[2];
  if (!day) {
    return "—"
  }
  if (day.includes('T') && day.includes('Z')) {
    day = day.slice(0, 2);
  }
  let month = dateValue.split("-")[1];
  let year = dateValue.split("-")[0];
  return day + "." + month + "." + year
});

nunjucksEnv.addFilter('from_translit', function (a) {
  a = a.replace(/target_transition/g, 'целевой-переход-состояния');
  a = a.replace(/display_name/g, 'отображаемое-имя');
  a = a.replace(/state/g, 'статус');
  a = a.replace(/shh/g, 'щ');
  a = a.replace(/yo/g, 'ё');
  a = a.replace(/zh/g, 'ж');
  a = a.replace(/cz/g, 'ц');
  a = a.replace(/ch/g, 'ч');
  a = a.replace(/sh/g, 'ш');
  a = a.replace(/yh/g, 'ы');
  a = a.replace(/qq/g, 'ъ');
  a = a.replace(/eh/g, 'э');
  a = a.replace(/yu/g, 'ю');
  a = a.replace(/ya/g, 'я');
  a = a.replace(/a/g, 'а');
  a = a.replace(/e/g, 'е');
  a = a.replace(/i/g, 'и');
  a = a.replace(/o/g, 'о');
  a = a.replace(/u/g, 'у');
  a = a.replace(/j/g, 'й');
  a = a.replace(/q/g, 'ь');
  a = a.replace(/b/g, 'б');
  a = a.replace(/v/g, 'в');
  a = a.replace(/g/g, 'г');
  a = a.replace(/d/g, 'д');
  a = a.replace(/z/g, 'з');
  a = a.replace(/k/g, 'к');
  a = a.replace(/l/g, 'л');
  a = a.replace(/m/g, 'м');
  a = a.replace(/n/g, 'н');
  a = a.replace(/p/g, 'п');
  a = a.replace(/r/g, 'р');
  a = a.replace(/s/g, 'с');
  a = a.replace(/t/g, 'т');
  a = a.replace(/f/g, 'ф');
  a = a.replace(/x/g, 'х');
  a = a.replace(/_/g, '-');
  return a;
});

const transform = (template, dataFile) => {
  console.log(chalk.blue('  ' + template + ' <- ' + dataFile));
  const fileContents = readFileSync('./jugdata/descriptions/' + dataFile, 'utf8');
  const data = yaml.loadAll(fileContents);
  return nunjucksEnv.render(template, data[0]);
}

const talks = JSON.parse(transform('talk2id.njk', 'talks.yml'));
const speakers = JSON.parse(transform('author2id.njk', 'speakers.yml'));
const ev_types = JSON.parse(transform('ev_type2id.njk', 'event-types.yml'));
const ev_type2ev = JSON.parse(transform('ev_type2ev.njk', 'events.yml'));

const combined = {
  talks: talks.talks,
  speakers: speakers.speakers,
  ev_types: ev_types.ev_types,
  ev_type2ev: ev_type2ev.ev_type2ev
};



writeFileSync('./combined.json', JSON.stringify(combined));

console.log('Сборка ADOC');

nunjucksEnv.addGlobal('lang', 'ru');
writeFileSync('./jekyll/talks_pre_ru.adoc',
  nunjucksEnv.render('talks.njk', combined));

nunjucksEnv.addGlobal('lang', 'en');
writeFileSync('./jekyll/talks_pre_en.adoc',
  nunjucksEnv.render('talks.njk', combined));
