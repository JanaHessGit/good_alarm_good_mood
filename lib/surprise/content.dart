import 'surprise.dart';

/// Starter content. Add to these lists freely: just give every new item a
/// unique id. Quizzes need exactly three options.
const List<Surprise> starterContent = [
  // Quizzes
  Surprise(id: 'z01', type: SurpriseType.quiz, text: 'How many hearts does an octopus have?',
      options: ['One', 'Two', 'Three'], answerIndex: 2,
      fact: 'Two hearts pump blood through the gills, and one pumps it through the rest of the body.',
      textDe: 'Wie viele Herzen hat ein Oktopus?',
      optionsDe: ['Eins', 'Zwei', 'Drei'],
      factDe: 'Zwei Herzen pumpen Blut durch die Kiemen, eines durch den restlichen Körper.'),
  Surprise(id: 'z02', type: SurpriseType.quiz, text: 'What is the largest ocean on Earth?',
      options: ['The Atlantic', 'The Pacific', 'The Indian Ocean'], answerIndex: 1,
      fact: 'The Pacific is bigger than all the land on Earth put together.',
      textDe: 'Welcher ist der größte Ozean der Erde?',
      optionsDe: ['Der Atlantik', 'Der Pazifik', 'Der Indische Ozean'],
      factDe: 'Der Pazifik ist größer als alle Landflächen der Erde zusammen.'),
  Surprise(id: 'z03', type: SurpriseType.quiz, text: 'What do bees mainly make honey from?',
      options: ['Pollen', 'Nectar', 'Tree sap'], answerIndex: 1,
      fact: 'Bees collect nectar from flowers and slowly dry it in the hive until it becomes honey.',
      textDe: 'Woraus machen Bienen vor allem Honig?',
      optionsDe: ['Aus Pollen', 'Aus Nektar', 'Aus Baumharz'],
      factDe: 'Bienen sammeln Nektar aus Blüten und trocknen ihn im Stock, bis Honig daraus wird.'),
  Surprise(id: 'z04', type: SurpriseType.quiz, text: 'How long does sunlight take to reach the Earth?',
      options: ['About 8 seconds', 'About 8 minutes', 'About 8 hours'], answerIndex: 1,
      fact: 'So the sunshine on your face right now left the sun about eight minutes ago.',
      textDe: 'Wie lange braucht Sonnenlicht bis zur Erde?',
      optionsDe: ['Etwa 8 Sekunden', 'Etwa 8 Minuten', 'Etwa 8 Stunden'],
      factDe: 'Die Sonnenstrahlen auf deinem Gesicht sind also vor etwa acht Minuten losgeflogen.'),
  Surprise(id: 'z05', type: SurpriseType.quiz, text: 'What is a baby kangaroo called?',
      options: ['A cub', 'A joey', 'A kit'], answerIndex: 1,
      fact: 'A newborn joey is about the size of a jelly bean.',
      textDe: 'Wie nennt man ein Kängurubaby?',
      optionsDe: ['Welpe', 'Joey', 'Kitz'],
      factDe: 'Ein neugeborenes Joey ist ungefähr so groß wie ein Gummibärchen.'),
  Surprise(id: 'z06', type: SurpriseType.quiz, text: 'Which country gave the Statue of Liberty to the United States?',
      options: ['France', 'Spain', 'Great Britain'], answerIndex: 0,
      fact: 'It arrived by ship in 1885, packed in more than two hundred crates.',
      textDe: 'Welches Land hat den USA die Freiheitsstatue geschenkt?',
      optionsDe: ['Frankreich', 'Spanien', 'Großbritannien'],
      factDe: 'Sie kam 1885 per Schiff an, verpackt in mehr als zweihundert Kisten.'),
  Surprise(id: 'z07', type: SurpriseType.quiz, text: 'How many bones does an adult human have?',
      options: ['106', '206', '306'], answerIndex: 1,
      fact: 'Babies are born with more, around 300, and some of them grow together over time.',
      textDe: 'Wie viele Knochen hat ein erwachsener Mensch?',
      optionsDe: ['106', '206', '306'],
      factDe: 'Babys haben bei der Geburt mehr, etwa 300. Einige davon wachsen später zusammen.'),
  Surprise(id: 'z08', type: SurpriseType.quiz, text: "What colour is a polar bear's skin?",
      options: ['White', 'Pink', 'Black'], answerIndex: 2,
      fact: 'Its fur only looks white. Each hair is actually see-through.',
      textDe: 'Welche Farbe hat die Haut eines Eisbären?',
      optionsDe: ['Weiß', 'Rosa', 'Schwarz'],
      factDe: 'Sein Fell sieht nur weiß aus. Jedes Haar ist eigentlich durchsichtig.'),
  Surprise(id: 'z09', type: SurpriseType.quiz, text: 'Which is the fastest land animal?',
      options: ['The lion', 'The cheetah', 'The horse'], answerIndex: 1,
      fact: 'A cheetah can go from standing still to 100 kilometres per hour in about three seconds.',
      textDe: 'Welches ist das schnellste Landtier?',
      optionsDe: ['Der Löwe', 'Der Gepard', 'Das Pferd'],
      factDe: 'Ein Gepard beschleunigt in etwa drei Sekunden von null auf hundert Kilometer pro Stunde.'),
  Surprise(id: 'z10', type: SurpriseType.quiz, text: 'In which city is the Brandenburg Gate?',
      options: ['Munich', 'Hamburg', 'Berlin'], answerIndex: 2,
      fact: 'It was finished in 1791 and was first meant as a symbol of peace.',
      textDe: 'In welcher Stadt steht das Brandenburger Tor?',
      optionsDe: ['München', 'Hamburg', 'Berlin'],
      factDe: 'Es wurde 1791 fertiggestellt und war zuerst als Symbol des Friedens gedacht.'),
  Surprise(id: 'z11', type: SurpriseType.quiz, text: 'Which planet has the most known moons?',
      options: ['Saturn', 'Mars', 'Venus'], answerIndex: 0,
      fact: 'Saturn has well over two hundred known moons. Venus has none at all.',
      textDe: 'Welcher Planet hat die meisten bekannten Monde?',
      optionsDe: ['Saturn', 'Mars', 'Venus'],
      factDe: 'Saturn hat weit über zweihundert bekannte Monde. Die Venus hat gar keinen.'),
  Surprise(id: 'z12', type: SurpriseType.quiz, text: 'What is the hardest natural material?',
      options: ['Gold', 'Diamond', 'Granite'], answerIndex: 1,
      fact: 'Diamond is pure carbon, the same element as the graphite in a pencil.',
      textDe: 'Was ist das härteste natürliche Material?',
      optionsDe: ['Gold', 'Diamant', 'Granit'],
      factDe: 'Diamant ist reiner Kohlenstoff, genau wie das Graphit in einem Bleistift.'),

  // Songs (Spotify ids checked on open.spotify.com)
  Surprise(id: 's01', type: SurpriseType.song, text: 'Here Comes the Sun', artist: 'The Beatles', spotifyId: '6dGnYIeXmHdcikdzNNDMm2'),
  Surprise(id: 's02', type: SurpriseType.song, text: 'Lovely Day', artist: 'Bill Withers', spotifyId: '0bRXwKfigvpKZUurwqAlEh'),
  Surprise(id: 's03', type: SurpriseType.song, text: 'Mr. Blue Sky', artist: 'Electric Light Orchestra', spotifyId: '2RlgNHKcydI9sayD2Df2xp'),
  Surprise(id: 's04', type: SurpriseType.song, text: 'Walking on Sunshine', artist: 'Katrina and the Waves', spotifyId: '05wIrZSwuaVWhcv5FfqeH0'),
  Surprise(id: 's05', type: SurpriseType.song, text: 'Three Little Birds', artist: 'Bob Marley & The Wailers', spotifyId: '6A9mKXlFRPMPem6ygQSt7z'),
  Surprise(id: 's06', type: SurpriseType.song, text: "Don't Stop Me Now", artist: 'Queen', spotifyId: '5T8EDUDqKcs6OSOwEsfqG7'),
  Surprise(id: 's07', type: SurpriseType.song, text: 'Beautiful Day', artist: 'U2', spotifyId: '1VuBmEauSZywQVtqbxNqka'),
  Surprise(id: 's08', type: SurpriseType.song, text: 'Wake Me Up', artist: 'Avicii', spotifyId: '0nrRP2bk19rLc0orkWPQk2'),
  Surprise(id: 's10', type: SurpriseType.song, text: 'Morning Has Broken', artist: 'Cat Stevens', spotifyId: '7dy51xaRi7glILvfRVNuFl', dayFit: DayFit.weekend),

  // Mini challenges. Each one gets you
  // out of bed right away, or plans something small for the day.
  Surprise(id: 'c01', type: SurpriseType.challenge, text: 'Get up and drink a full glass of water before anything else.', textDe: 'Steh auf und trink ein volles Glas Wasser, bevor du irgendetwas anderes machst.'),
  Surprise(id: 'c03', type: SurpriseType.challenge, text: 'Get up and do ten squats right next to your bed.', textDe: 'Steh auf und mach zehn Kniebeugen direkt neben deinem Bett.'),
  Surprise(id: 'c06', type: SurpriseType.challenge, text: 'Open the window and stretch in the fresh air for two minutes.', textDe: 'Öffne das Fenster und streck dich zwei Minuten lang an der frischen Luft.'),
  Surprise(id: 'c07', type: SurpriseType.challenge, text: 'Get up and tidy just one drawer. Only one.', textDe: 'Steh auf und räum genau eine Schublade auf. Nur eine.'),
  Surprise(id: 'c08', type: SurpriseType.challenge, text: 'Walk to the kitchen and make your favourite breakfast drink, slowly and properly.', textDe: 'Geh in die Küche und mach dir dein Lieblings-Frühstücksgetränk, in aller Ruhe.'),
  Surprise(id: 'c09', type: SurpriseType.challenge, text: 'Stand at the window and find three things outside that are moving.', textDe: 'Stell dich ans Fenster und finde draußen drei Dinge, die sich bewegen.'),
  Surprise(id: 'c02', type: SurpriseType.challenge, text: 'Keep your phone away for the first twenty minutes after you get up.', textDe: 'Lass dein Handy nach dem Aufstehen zwanzig Minuten lang liegen.'),
  Surprise(id: 'c04', type: SurpriseType.challenge, text: "Send a message to someone you haven't talked to in a while.", textDe: 'Schreib heute jemandem, von dem du lange nichts gehört hast.'),
  Surprise(id: 'c05', type: SurpriseType.challenge, text: 'Give one honest compliment before noon.', textDe: 'Mach vor zwölf Uhr jemandem ein ehrliches Kompliment.'),
  Surprise(id: 'a01', type: SurpriseType.challenge, text: 'Take a different route to work or the shop today.', textDe: 'Nimm heute einen anderen Weg zur Arbeit oder zum Einkaufen.', dayFit: DayFit.weekday),
  Surprise(id: 'a02', type: SurpriseType.challenge, text: "Eat lunch outside, even if it's only for ten minutes.", textDe: 'Iss heute draußen zu Mittag, auch wenn es nur zehn Minuten sind.', dayFit: DayFit.weekday),
  Surprise(id: 'a03', type: SurpriseType.challenge, text: "Buy one fruit or snack you've never tried before.", textDe: 'Kauf heute ein Obst oder einen Snack, den du noch nie probiert hast.', dayFit: DayFit.weekday),
  Surprise(id: 'a04', type: SurpriseType.challenge, text: 'On your way home, find the oldest building you pass.', textDe: 'Such auf dem Heimweg das älteste Gebäude, an dem du vorbeikommst.', dayFit: DayFit.weekday),
  Surprise(id: 'a05', type: SurpriseType.challenge, text: "Walk to the end of a street you've never been down.", textDe: 'Lauf bis zum Ende einer Straße, in der du noch nie warst.', dayFit: DayFit.weekend),
  Surprise(id: 'a06', type: SurpriseType.challenge, text: "Visit a café you've walked past but never entered.", textDe: 'Geh in ein Café, an dem du schon oft vorbeigelaufen bist, aber nie drin warst.', dayFit: DayFit.weekend),
  Surprise(id: 'a07', type: SurpriseType.challenge, text: 'Take the first bus that comes and ride three stops. Explore, then come back.', textDe: 'Nimm den nächsten Bus und fahr drei Stationen. Schau dich um und fahr dann zurück.', dayFit: DayFit.weekend),
  Surprise(id: 'a08', type: SurpriseType.challenge, text: 'Watch the sunset from the highest spot you can reach nearby.', textDe: 'Schau dir den Sonnenuntergang vom höchsten Punkt in deiner Nähe an.', dayFit: DayFit.weekend),
  Surprise(id: 'a09', type: SurpriseType.challenge, text: "Look up: find three things above eye level you've never noticed.", textDe: 'Schau nach oben: Finde drei Dinge über Augenhöhe, die dir noch nie aufgefallen sind.'),
  Surprise(id: 'a10', type: SurpriseType.challenge, text: 'Write a postcard to a friend and post it today.', textDe: 'Schreib einer Freundin oder einem Freund eine Postkarte und wirf sie heute noch ein.'),

  // Riddles: the voice repeats the riddle until Show answer is tapped.
  Surprise(id: 'r01', type: SurpriseType.riddle, text: 'The more of them you take, the more you leave behind. What are they?', answer: 'Footsteps',
      textDe: 'Je mehr du davon machst, desto mehr lässt du hinter dir. Was ist das?', answerDe: 'Schritte'),
  Surprise(id: 'r02', type: SurpriseType.riddle, text: 'What has a neck but no head?', answer: 'A bottle',
      textDe: 'Was hat einen Hals, aber keinen Kopf?', answerDe: 'Eine Flasche'),
  Surprise(id: 'r03', type: SurpriseType.riddle, text: 'What gets wetter the more it dries?', answer: 'A towel',
      textDe: 'Was wird nasser, je mehr es trocknet?', answerDe: 'Ein Handtuch'),
  Surprise(id: 'r04', type: SurpriseType.riddle, text: 'What has a face and two hands, but no arms or legs?', answer: 'A clock',
      textDe: 'Was läuft und läuft, hat aber keine Beine?', answerDe: 'Eine Uhr'),
  Surprise(id: 'r05', type: SurpriseType.riddle, text: 'I have cities but no houses, forests but no trees, and water but no fish. What am I?', answer: 'A map',
      textDe: 'Ich habe Städte, aber keine Häuser, Wälder, aber keine Bäume, und Wasser, aber keine Fische. Was bin ich?', answerDe: 'Eine Landkarte'),
  Surprise(id: 'r06', type: SurpriseType.riddle, text: 'What goes up but never comes down?', answer: 'Your age',
      textDe: 'Was steigt jedes Jahr, kommt aber nie wieder herunter?', answerDe: 'Dein Alter'),
  Surprise(id: 'r07', type: SurpriseType.riddle, text: 'What has to be broken before you can use it?', answer: 'An egg',
      textDe: 'Was muss man zerbrechen, bevor man es benutzen kann?', answerDe: 'Ein Ei'),
  Surprise(id: 'r08', type: SurpriseType.riddle, text: 'What belongs to you, but other people use it more than you do?', answer: 'Your name',
      textDe: 'Was gehört dir, wird aber von anderen viel öfter benutzt als von dir?', answerDe: 'Dein Name'),
  Surprise(id: 'r09', type: SurpriseType.riddle, text: 'What can fill a whole room but takes up no space?', answer: 'Light',
      textDe: 'Was kann einen ganzen Raum füllen, braucht aber keinen Platz?', answerDe: 'Licht'),
  Surprise(id: 'r10', type: SurpriseType.riddle, text: 'What has lots of teeth but never bites?', answer: 'A comb',
      textDe: 'Was hat viele Zähne, beißt aber nie?', answerDe: 'Ein Kamm'),
  Surprise(id: 'r11', type: SurpriseType.riddle, text: 'What is always in front of you but can never be seen?', answer: 'The future',
      textDe: 'Was liegt immer vor dir, aber du kannst es nie sehen?', answerDe: 'Die Zukunft'),
  Surprise(id: 'r12', type: SurpriseType.riddle, text: 'What has one eye but cannot see?', answer: 'A needle',
      textDe: 'Was hat ein Öhr, kann aber nichts hören?', answerDe: 'Eine Nadel'),

  // Story time (about three minutes each, read aloud)
  Surprise(id: 't01', type: SurpriseType.story, title: 'The Sock Who Wanted to See the Sea', mood: 'Funny', text: _storySock,
      titleDe: 'Die Socke, die das Meer sehen wollte', moodDe: 'Lustig', textDe: _storySockDe),
  Surprise(id: 't02', type: SurpriseType.story, title: 'The Bread on the Windowsill', mood: 'Heartwarming', text: _storyBread,
      titleDe: 'Das Brot auf dem Fensterbrett', moodDe: 'Herzerwärmend', textDe: _storyBreadDe),
  Surprise(id: 't03', type: SurpriseType.story, title: 'The Letter in the Library Book', mood: 'Moving', text: _storyLetter,
      titleDe: 'Der Brief im Bibliotheksbuch', moodDe: 'Berührend', textDe: _storyLetterDe),
];

const _storySock = '''
In the second drawer of a tall wooden dresser lived a striped yellow sock named Bernard. Bernard was a left sock, and like most left socks, he was the thoughtful one of the pair. His partner, the right sock, mostly thought about lunch.

Every Sunday, Bernard went into the washing machine. And every Sunday, while he spun round and round in the warm, soapy water, he heard the same thing through the little round window: the gentle whoosh, whoosh of the waves. At least, that's what he thought it was. "That," he told the other socks, "is the sea. And one day, I am going to see it."

The other socks laughed. "Socks don't go to the sea," said an old grey hiking sock. "Socks go in drawers. That's the whole job."

But Bernard had a plan. On laundry day, when the basket was carried to the machine, he wriggled to the very top. When the door opened, he jumped. He did not land in the machine. He landed behind it, in the dark, dusty place where lost socks go.

And there he found them. Dozens of socks. A red one with reindeer. A tiny baby sock with a duck on it. A sock so old it had forgotten its own colour. "Welcome," said the reindeer sock. "We're the Lost Sock Society. We meet every day. Mostly to complain."

"I'm not lost," said Bernard. "I'm travelling. I'm going to see the sea."

The socks went quiet. Nobody had ever said anything so brave behind a washing machine before. "How?" whispered the baby sock.

Bernard didn't know. But just then, a hand reached behind the machine. It was the girl who lived in the house, with a flashlight and a very determined face. "There you are!" she said, and pulled out every single sock in one big, dusty bundle. "We're packing for the beach tomorrow, and I need all of you."

The next morning, Bernard sat in a suitcase, squeezed between a sun hat and a bottle of sunscreen. He could hardly breathe from excitement. The car drove for hours. Then the suitcase opened, and the girl put Bernard on her left foot, and his partner on her right, and she ran. Down the path, over the dunes, and there it was.

The sea. Enormous, blue and sparkling, with real waves that went whoosh, whoosh, exactly like the washing machine, only much, much bigger.

The girl took off her shoes and socks and laid Bernard on a warm rock to watch while she swam. And Bernard looked at the sea for the whole afternoon, perfectly happy.

That evening, back in the suitcase, the right sock asked, "So? Was it worth it?"

Bernard smiled, as much as a sock can smile. "It was even better than the washing machine," he said. "And tomorrow, I'm going to see a mountain."
''';

const _storyBread = '''
Every morning at half past five, long before the street woke up, Mr. Albers unlocked the door of his little bakery. He had done it for forty-one years. He knew every creak of the old floor and every mood of the old oven, which liked to be talked to before it got really hot.

On a cold Tuesday in November, he noticed something on the windowsill outside: a small paper bag, folded neatly at the top. Inside was a drawing. A wobbly brown loaf of bread with a huge smile, drawn in crayon. Underneath, in careful letters, someone had written: "Your bread makes our mornings happy. From Lina, age seven."

Mr. Albers laughed out loud, alone in his shop. He pinned the drawing next to the cash register, where everyone could see it.

The next morning, he left a small, warm roll on the windowsill, wrapped in a napkin, with a note: "For Lina. Thank you for the picture. The bread says hello."

The following day, the roll was gone, and there was a new drawing. This time it was the bakery itself, with a very tall baker in the doorway and tiny hearts coming out of the chimney.

And so it began. Every morning, a roll went out, and every morning, a drawing came back. A cat sitting on a pretzel. The moon eating a croissant. Mr. Albers in a cape, flying over the city with a baguette like a sword. The wall next to the cash register slowly filled up, and customers started coming in just to see the newest one.

Then, one week in January, the drawings stopped. The rolls stayed on the windowsill, cold and untouched. Mr. Albers worried more than he wanted to admit. He didn't even know where Lina lived.

On the fifth day, a woman came into the shop. She looked tired, but she was smiling. "I'm Lina's mother," she said. "Lina has been in hospital for a week. Nothing serious, she's getting better. But she asked me to give you something."

She held out a folded sheet of paper. It was a drawing of a hospital bed, and on the bed sat a small girl with a very large roll in her hands. Above it, in bright letters: "I miss your bread. Save me one."

The next morning, the whole street was a little surprised. On the bakery's windowsill sat a basket. Inside were seven rolls, one for each day she'd missed, and a note in big, careful baker's letters: "For Lina. We all saved you one."

Because next to the note, there were more things. A small teddy bear from the flower shop. A get-well card from the bus driver. A chocolate from the woman at the newspaper stand. The whole street had heard the story.

Two weeks later, the paper bag was back on the windowsill. Inside was a drawing of the entire street, every shop and every neighbour, all holding hands. And in the middle, standing next to a very tall baker, was a small, smiling girl.

Mr. Albers pinned it right in the centre of the wall. It is still there today.
''';

const _storyLetter = '''
Mara was nineteen and new in the city, and on most days she felt like a visitor in her own life. She didn't know anyone yet. So in the evenings, she went to the library, because it was warm, and quiet, and nobody there expected her to have friends.

One evening, she borrowed an old book of poems with a faded green cover. When she opened it at home, a folded piece of paper slipped out and floated to the floor. It was a letter, written in blue ink, in tidy, old-fashioned handwriting.

"Dear stranger," it began. "If you are reading this, you picked up a book that nobody has borrowed in a long time. That probably means you are a little bit like me. I am eighty-three years old. I have lived in this city all my life, and I still sometimes feel like I'm waiting for it to notice me. So I am leaving this letter here, to tell you something I wish someone had told me at your age, whatever age you are. You are not late. You are not behind. The good people in your life are on their way to you, and some of them haven't even met you yet. Be patient with yourself. And please, be kind to the librarian with the red glasses. She has had a hard year. Warmly, Elsa."

Mara read it three times. Then she cried a little, which surprised her, because she hadn't cried since she moved.

The next evening, she went back to the library. Behind the desk stood a librarian with red glasses. Mara hesitated, then said, "I just wanted to say, your library is my favourite place in this city."

The librarian looked up, and for a moment she couldn't speak. "Thank you," she said finally. "You have no idea how much I needed to hear that today." Her name was Jo. They talked for half an hour, about books and about cities and about starting over.

Mara came back the next day, and the day after that. Jo introduced her to the reading group on Thursdays. In the reading group, Mara met two students her age, who invited her to a concert. At the concert, she laughed so hard that she spilled her drink on a stranger, and the stranger became her best friend.

Months later, Mara asked Jo about Elsa. Jo smiled. "Elsa comes every Wednesday morning," she said. "She always sits by the window."

So the next Wednesday, Mara brought the green book, and the letter, and a coffee. She walked up to a small woman with white hair and bright eyes by the window. "I think this is yours," she said. "And I think you were right. About everything."

Elsa looked at the letter, then at Mara, and her whole face lit up. "Oh," she said. "You found it. Sit down, dear. Tell me everything."

And Mara did.

Before she left that day, Mara wrote a letter of her own. "Dear stranger," it began. And she slipped it into a book that nobody had borrowed in a very long time.
''';

const _storySockDe = '''
In der zweiten Schublade einer hohen Holzkommode wohnte eine gelb gestreifte Socke namens Bernhard. Bernhard war eine linke Socke, und wie die meisten linken Socken war er der Nachdenkliche von beiden. Seine Partnerin, die rechte Socke, dachte vor allem ans Mittagessen.

Jeden Sonntag kam Bernhard in die Waschmaschine. Und jeden Sonntag, während er sich im warmen Seifenwasser im Kreis drehte, hörte er durch das kleine runde Fenster dasselbe Geräusch: ein sanftes Rauschen, wusch, wusch. Jedenfalls glaubte er das. „Das", erklärte er den anderen Socken, „ist das Meer. Und eines Tages werde ich es sehen."

Die anderen Socken lachten. „Socken fahren nicht ans Meer", sagte eine alte graue Wandersocke. „Socken liegen in Schubladen. Das ist unser ganzer Job."

Aber Bernhard hatte einen Plan. Am Waschtag, als der Wäschekorb zur Maschine getragen wurde, zappelte er sich ganz nach oben. Als die Tür aufging, sprang er. Er landete nicht in der Maschine. Er landete dahinter, an dem dunklen, staubigen Ort, an dem verlorene Socken landen.

Und dort fand er sie. Dutzende Socken. Eine rote mit Rentieren. Eine winzige Babysocke mit einer Ente darauf. Eine Socke, so alt, dass sie ihre eigene Farbe vergessen hatte. „Willkommen", sagte die Rentiersocke. „Wir sind der Verein der verlorenen Socken. Wir treffen uns jeden Tag. Meistens, um uns zu beschweren."

„Ich bin nicht verloren", sagte Bernhard. „Ich bin auf Reisen. Ich will das Meer sehen."

Die Socken wurden still. So etwas Mutiges hatte hinter einer Waschmaschine noch nie jemand gesagt. „Wie denn?", flüsterte die Babysocke.

Bernhard wusste es nicht. Doch genau in diesem Moment griff eine Hand hinter die Maschine. Es war das Mädchen, das im Haus wohnte, mit einer Taschenlampe und einem sehr entschlossenen Gesicht. „Da seid ihr ja!", rief sie und zog alle Socken in einem großen, staubigen Knäuel heraus. „Wir packen für den Strand morgen, und ich brauche euch alle."

Am nächsten Morgen saß Bernhard in einem Koffer, eingeklemmt zwischen einem Sonnenhut und einer Flasche Sonnencreme. Er konnte vor Aufregung kaum atmen. Das Auto fuhr stundenlang. Dann ging der Koffer auf, das Mädchen zog Bernhard über den linken Fuß und seine Partnerin über den rechten, und sie rannte los. Den Weg hinunter, über die Dünen, und da war es.

Das Meer. Riesig, blau und glitzernd, mit echten Wellen, die wusch, wusch machten, genau wie die Waschmaschine, nur viel, viel größer.

Das Mädchen zog Schuhe und Socken aus und legte Bernhard auf einen warmen Felsen, damit er zuschauen konnte, während sie schwamm. Und Bernhard schaute den ganzen Nachmittag aufs Meer, vollkommen glücklich.

Am Abend, zurück im Koffer, fragte die rechte Socke: „Und? Hat es sich gelohnt?"

Bernhard lächelte, so gut eine Socke eben lächeln kann. „Es war sogar noch besser als die Waschmaschine", sagte er. „Und morgen sehe ich mir einen Berg an."
''';

const _storyBreadDe = '''
Jeden Morgen um halb sechs, lange bevor die Straße aufwachte, schloss Herr Albers die Tür seiner kleinen Bäckerei auf. Das tat er seit einundvierzig Jahren. Er kannte jedes Knarren des alten Bodens und jede Laune des alten Ofens, der gern ein bisschen angesprochen werden wollte, bevor er richtig heiß wurde.

An einem kalten Dienstag im November bemerkte er etwas auf dem Fensterbrett draußen: eine kleine Papiertüte, oben ordentlich gefaltet. Darin lag ein Bild. Ein wackeliges braunes Brot mit einem riesigen Lächeln, gemalt mit Wachsmalstiften. Darunter stand in sorgfältigen Buchstaben: „Dein Brot macht unsere Morgen glücklich. Von Lina, sieben Jahre."

Herr Albers lachte laut, ganz allein in seinem Laden. Er hängte das Bild neben die Kasse, wo es jeder sehen konnte.

Am nächsten Morgen legte er ein kleines, warmes Brötchen aufs Fensterbrett, in eine Serviette gewickelt, mit einem Zettel: „Für Lina. Danke für das Bild. Das Brot lässt grüßen."

Am Tag darauf war das Brötchen weg, und es lag ein neues Bild da. Diesmal war es die Bäckerei selbst, mit einem sehr großen Bäcker in der Tür und kleinen Herzen, die aus dem Schornstein kamen.

Und so fing es an. Jeden Morgen ging ein Brötchen hinaus, und jeden Morgen kam ein Bild zurück. Eine Katze, die auf einer Brezel saß. Der Mond, der ein Croissant aß. Herr Albers mit Umhang, wie er mit einem Baguette als Schwert über die Stadt flog. Die Wand neben der Kasse füllte sich langsam, und die Kundschaft kam bald nur, um das neueste Bild zu sehen.

Dann, in einer Woche im Januar, kamen keine Bilder mehr. Die Brötchen blieben auf dem Fensterbrett liegen, kalt und unberührt. Herr Albers machte sich mehr Sorgen, als er zugeben wollte. Er wusste nicht einmal, wo Lina wohnte.

Am fünften Tag kam eine Frau in den Laden. Sie sah müde aus, aber sie lächelte. „Ich bin Linas Mama", sagte sie. „Lina liegt seit einer Woche im Krankenhaus. Nichts Schlimmes, es geht ihr schon besser. Aber sie hat mich gebeten, Ihnen etwas zu geben."

Sie reichte ihm ein gefaltetes Blatt. Darauf war ein Krankenhausbett gemalt, und auf dem Bett saß ein kleines Mädchen mit einem sehr großen Brötchen in den Händen. Darüber stand in leuchtenden Buchstaben: „Ich vermisse dein Brot. Heb mir eins auf."

Am nächsten Morgen staunte die ganze Straße ein bisschen. Auf dem Fensterbrett der Bäckerei stand ein Korb. Darin lagen sieben Brötchen, eins für jeden Tag, den sie verpasst hatte, und ein Zettel in großer, sorgfältiger Bäckerschrift: „Für Lina. Wir haben dir alle eins aufgehoben."

Denn neben dem Zettel lagen noch mehr Dinge. Ein kleiner Teddy aus dem Blumenladen. Eine Gute-Besserung-Karte vom Busfahrer. Eine Schokolade von der Frau am Zeitungskiosk. Die ganze Straße hatte die Geschichte gehört.

Zwei Wochen später lag die Papiertüte wieder auf dem Fensterbrett. Darin war ein Bild der ganzen Straße, jeder Laden und jeder Nachbar, alle hielten sich an den Händen. Und in der Mitte, neben einem sehr großen Bäcker, stand ein kleines, lächelndes Mädchen.

Herr Albers hängte es genau in die Mitte der Wand. Dort hängt es noch heute.
''';

const _storyLetterDe = '''
Mara war neunzehn und neu in der Stadt, und an den meisten Tagen fühlte sie sich wie eine Besucherin in ihrem eigenen Leben. Sie kannte noch niemanden. Also ging sie abends in die Bibliothek, weil es dort warm und still war und niemand erwartete, dass sie schon Freunde hatte.

Eines Abends lieh sie sich einen alten Gedichtband mit verblichenem grünem Einband aus. Als sie ihn zu Hause aufschlug, rutschte ein gefaltetes Blatt heraus und segelte zu Boden. Es war ein Brief, geschrieben mit blauer Tinte, in einer ordentlichen, altmodischen Handschrift.

„Liebe fremde Person", begann er. „Wenn du das liest, hast du ein Buch in die Hand genommen, das lange niemand ausgeliehen hat. Dann bist du wahrscheinlich ein bisschen wie ich. Ich bin dreiundachtzig Jahre alt. Ich habe mein ganzes Leben in dieser Stadt verbracht, und manchmal warte ich immer noch darauf, dass sie mich bemerkt. Deshalb lege ich diesen Brief hierher, um dir etwas zu sagen, das ich in deinem Alter gern gehört hätte, egal wie alt du bist. Du bist nicht zu spät. Du bist nicht hinterher. Die guten Menschen in deinem Leben sind schon auf dem Weg zu dir, und manche von ihnen kennen dich noch gar nicht. Sei geduldig mit dir. Und bitte sei freundlich zu der Bibliothekarin mit der roten Brille. Sie hatte ein schweres Jahr. Herzlich, Elsa."

Mara las den Brief dreimal. Dann weinte sie ein bisschen, was sie überraschte, denn sie hatte seit dem Umzug nicht geweint.

Am nächsten Abend ging sie wieder in die Bibliothek. Hinter dem Tresen stand eine Bibliothekarin mit roter Brille. Mara zögerte, dann sagte sie: „Ich wollte nur sagen, Ihre Bibliothek ist mein Lieblingsort in dieser Stadt."

Die Bibliothekarin sah auf, und einen Moment lang brachte sie kein Wort heraus. „Danke", sagte sie schließlich. „Sie haben keine Ahnung, wie sehr ich das heute gebraucht habe." Sie hieß Jo. Die beiden redeten eine halbe Stunde lang, über Bücher, über Städte und über Neuanfänge.

Mara kam am nächsten Tag wieder und am Tag danach. Jo stellte sie dem Lesekreis am Donnerstag vor. Im Lesekreis lernte Mara zwei Studierende in ihrem Alter kennen, die sie zu einem Konzert einluden. Beim Konzert lachte sie so sehr, dass sie ihr Getränk über einen Fremden kippte, und der Fremde wurde ihr bester Freund.

Monate später fragte Mara Jo nach Elsa. Jo lächelte. „Elsa kommt jeden Mittwochmorgen", sagte sie. „Sie sitzt immer am Fenster."

Also brachte Mara am nächsten Mittwoch das grüne Buch mit, den Brief und einen Kaffee. Sie ging zu einer kleinen Frau mit weißen Haaren und hellen Augen am Fenster. „Ich glaube, das gehört Ihnen", sagte sie. „Und ich glaube, Sie hatten recht. Mit allem."

Elsa sah auf den Brief, dann auf Mara, und ihr ganzes Gesicht begann zu leuchten. „Oh", sagte sie. „Du hast ihn gefunden. Setz dich, meine Liebe. Erzähl mir alles."

Und Mara erzählte.

Bevor sie an diesem Tag ging, schrieb Mara einen eigenen Brief. „Liebe fremde Person", begann er. Und sie schob ihn in ein Buch, das sehr lange niemand ausgeliehen hatte.
''';
