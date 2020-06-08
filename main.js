const { readFileSync, writeFileSync } = require('fs');
const { resolve, basename, dirname } = require('path');
const nunjucks = require('nunjucks');
const mkdirp = require('mkdirp');
const chalk = require('chalk').default;
const yaml = require('js-yaml');

console.log('Подготовка json-файлов с нужной иерархией');

const inputDir = resolve(process.cwd(), './njk') || '';

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

nunjucksEnv.addFilter('youtube_id', function (a) {
  var regExp = /^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#&?]*).*/;
  var match = a.match(regExp);
  return (match && match[7].length == 11) ? match[7] : false;
});

const transform = (template, dataFile, mapFunc = x => x) => {
  console.log(chalk.blue(`  ${template} <- ${dataFile}`));
  const fileContents = readFileSync(`./jugdata/descriptions/${dataFile}`, 'utf8');
  const data = yaml.loadAll(fileContents)[0];
  return nunjucksEnv.render(template, mapFunc(data));
}

/* During the parsing we collect speaker -> talks map */
const speakerTalks = {};
const talks = JSON.parse(transform('talk2id.njk', 'talks.yml',
  data => {
    for (talk of data.talks) {
      for (speakerid of talk.speakerIds) {
        if (speakerTalks[speakerid] == undefined) {
          speakerTalks[speakerid] = [talk.id];
        } else {
          speakerTalks[speakerid].push(talk.id);
        }
      }
    }
    return data;
  }
));

/* Here we also enrich each speaker's profile with their talks */
const speakers = JSON.parse(transform('author2id.njk', 'speakers.yml',
  data => {
    for (speaker of data.speakers) {
      speaker.talks = speakerTalks[speaker.id];
    }
    return data;
  }
));


const ev_types = JSON.parse(transform('ev_type2id.njk', 'event-types.yml'));

const ev_type2ev = JSON.parse(transform('ev_type2ev.njk', 'events.yml',
  /*here we generate event ids for cross-references */
  data => {
    var i = 0;
    for (event of data.events) {
      i++;
      event.event_id = i;
      /* add links from talk to event */
      for (talk_id of event.talkIds) {
        talks.talks[talk_id].event = event;
      }
    }
    return data;
  }));

const places = yaml.loadAll(readFileSync('./jugdata/descriptions/places.yml', 'utf8'))[0];

/* Group speaker talks by type */
for (speaker of Object.values(speakers.speakers)) {
  speaker.talks = {}
  if (speakerTalks[speaker.id])
    for (talk_id of speakerTalks[speaker.id]) {
      const event = talks.talks[talk_id].event;
      if (speaker.talks[event.eventTypeId]) {
        speaker.talks[event.eventTypeId].push(talk_id);
      } else {
        speaker.talks[event.eventTypeId] = [talk_id];
      }
    }
}

const combined = {
  talks: talks.talks,
  speakers: speakers.speakers,
  ev_types: ev_types.ev_types,
  ev_type2ev: ev_type2ev.ev_type2ev,
  places: places.places
};



writeFileSync('combined.json', JSON.stringify(combined, null, 2));

console.log('Сборка ADOC');

var lang;

for (lang of ['ru', 'en']) {
  nunjucksEnv.addGlobal('lang', lang);
  console.log(chalk.blue(`  ${lang}`));
  //here we procude all the files for the given language
  //writeFileSync(`./jekyll/${lang}/talks_pre.adoc`,
  //  nunjucksEnv.render('talks.njk', combined));

  console.log(chalk.blue(`    Event types and events list...`));
  mkdirp.sync(`./jekyll/${lang}`);
  writeFileSync(`./jekyll/${lang}/events.adoc`,
    nunjucksEnv.render('events.njk', combined));

  console.log(chalk.blue(`    Speakers list...`));
  writeFileSync(`./jekyll/${lang}/speakers.adoc`,
    nunjucksEnv.render('speakers.njk', combined));

  console.log(chalk.blue(`    Event type cards...`));
  mkdirp.sync(`./jekyll/${lang}/evttype`);
  for (ev_type_id of Object.keys(combined.ev_types)) {
    nunjucksEnv.addGlobal('ev_type_id', ev_type_id);
    writeFileSync(`./jekyll/${lang}/evttype/${ev_type_id}.adoc`,
      nunjucksEnv.render('evttype.njk', combined));
  }

  console.log(chalk.blue(`    Event cards...`));
  mkdirp.sync(`./jekyll/${lang}/event`);
  for (event_type of Object.values(combined.ev_type2ev))
    for (event of event_type) {
      nunjucksEnv.addGlobal('event_item', event);
      writeFileSync(`./jekyll/${lang}/event/${event.event_id}.adoc`,
        nunjucksEnv.render('event_card.njk', combined));
    }

  console.log(chalk.blue(`    Speaker cards...`));
  mkdirp.sync(`./jekyll/${lang}/speaker`);
  for (speaker of Object.values(combined.speakers)) {
    nunjucksEnv.addGlobal('speaker', speaker);
    writeFileSync(`./jekyll/${lang}/speaker/${speaker.id}.adoc`,
      nunjucksEnv.render('speaker_card.njk', combined));
  }

  console.log(chalk.blue(`    Talk cards...`));
  mkdirp.sync(`./jekyll/${lang}/talk`);
  for (talk of Object.values(combined.talks)) {
    nunjucksEnv.addGlobal('talk', talk);
    writeFileSync(`./jekyll/${lang}/talk/${talk.id}.adoc`,
      nunjucksEnv.render('talk_card.njk', combined));
  }

}

console.log('Done.');
