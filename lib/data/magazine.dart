import 'package:flutter/material.dart';

import '../theme.dart';

/// The kinds of rubric a magazine issue can contain. Order here is the order
/// they appear in the table of contents.
enum RubricKind { story, breed, facts, comic, recipe, wordSearch, quiz }

extension RubricKindX on RubricKind {
  String get label {
    switch (this) {
      case RubricKind.story:
        return 'Folk Tale';
      case RubricKind.breed:
        return 'Breed of the Month';
      case RubricKind.facts:
        return 'Did You Know?';
      case RubricKind.comic:
        return 'Comic Strip';
      case RubricKind.recipe:
        return 'From the Coop Kitchen';
      case RubricKind.wordSearch:
        return 'Word Search';
      case RubricKind.quiz:
        return 'Quiz Corner';
    }
  }

  IconData get icon {
    switch (this) {
      case RubricKind.story:
        return Icons.auto_stories_rounded;
      case RubricKind.breed:
        return Icons.pets_rounded;
      case RubricKind.facts:
        return Icons.lightbulb_rounded;
      case RubricKind.comic:
        return Icons.view_agenda_rounded;
      case RubricKind.recipe:
        return Icons.restaurant_rounded;
      case RubricKind.wordSearch:
        return Icons.grid_on_rounded;
      case RubricKind.quiz:
        return Icons.quiz_rounded;
    }
  }

  bool get isInteractive =>
      this == RubricKind.wordSearch || this == RubricKind.quiz;
}

class Story {
  const Story({
    required this.title,
    required this.origin,
    required this.flag,
    required this.paragraphs,
    required this.moral,
  });
  final String title;
  final String origin;
  final String flag;
  final List<String> paragraphs;
  final String moral;
}

class Breed {
  const Breed({
    required this.name,
    required this.origin,
    required this.asset,
    required this.blurb,
    required this.facts,
    required this.accent,
  });
  final String name;
  final String origin;
  final String asset;
  final String blurb;
  final List<String> facts;
  final Color accent;
}

class Recipe {
  const Recipe({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.minutes,
    required this.difficulty,
    required this.ingredients,
    required this.steps,
    required this.tip,
  });
  final String title;
  final String subtitle;
  final String emoji;
  final int minutes;
  final String difficulty;
  final List<String> ingredients;
  final List<String> steps;
  final String tip;
}

class ComicPanel {
  const ComicPanel(this.emoji, this.caption);
  final String emoji;
  final String caption;
}

class Comic {
  const Comic({required this.title, required this.panels});
  final String title;
  final List<ComicPanel> panels;
}

class QuizQuestion {
  const QuizQuestion(this.question, this.options, this.answer);
  final String question;
  final List<String> options;
  final int answer;
}

class Quiz {
  const Quiz({required this.title, required this.questions});
  final String title;
  final List<QuizQuestion> questions;
}

class WordSearch {
  const WordSearch({
    required this.title,
    required this.words,
    this.size = 10,
  });
  final String title;
  final List<String> words;
  final int size;
}

class Issue {
  const Issue({
    required this.number,
    required this.month,
    required this.year,
    required this.title,
    required this.tagline,
    required this.coverEmoji,
    required this.coverColor,
    required this.story,
    required this.facts,
    required this.breed,
    required this.comic,
    required this.recipe,
    required this.wordSearch,
    required this.quiz,
  });

  final int number;
  final String month;
  final String year;
  final String title;
  final String tagline;
  final String coverEmoji;
  final Color coverColor;

  final Story story;
  final List<String> facts;
  final Breed breed;
  final Comic comic;
  final Recipe recipe;
  final WordSearch wordSearch;
  final Quiz quiz;

  String get dateLine => '$month $year';

  /// Stable id for a rubric within this issue (used for progress tracking).
  String rubricId(RubricKind kind) => '$number:${kind.name}';

  List<RubricKind> get rubrics => const [
        RubricKind.story,
        RubricKind.breed,
        RubricKind.facts,
        RubricKind.comic,
        RubricKind.recipe,
        RubricKind.wordSearch,
        RubricKind.quiz,
      ];
}

// ─────────────────────────────────────────────────────────────────────────
// BREEDS
// ─────────────────────────────────────────────────────────────────────────

const _leghorn = Breed(
  name: 'Leghorn',
  origin: 'Tuscany, Italy 🇮🇹',
  asset: AppAssets.leghorn,
  accent: AppColors.folkBlue,
  blurb:
      'Slim, snowy-white and always on the move — the Leghorn is the sports '
      'star of the hen house.',
  facts: [
    'Leghorns come from the port city of Livorno in Italy.',
    'They are champion layers of large, chalk-white eggs.',
    'A busy Leghorn can lay around 280 eggs in a single year.',
    'The cartoon rooster Foghorn Leghorn was named after the breed!',
  ],
);

const _silkie = Breed(
  name: 'Silkie',
  origin: 'Ancient China 🇨🇳',
  asset: AppAssets.silkie,
  accent: Color(0xFF4A4A6A),
  blurb:
      'A living powder-puff. The Silkie’s feathers feel like fur and its heart '
      'is famously gentle.',
  facts: [
    'Silkie feathers lack the tiny hooks that hold normal feathers flat — so '
        'they look fluffy like fur.',
    'Silkies have black skin and bones, and five toes instead of the usual four.',
    'Explorer Marco Polo wrote about “furry chickens” on his travels centuries ago.',
    'They make such caring mothers they will happily hatch other birds’ eggs.',
  ],
);

const _buff = Breed(
  name: 'Buff Orpington',
  origin: 'Kent, England 🇬🇧',
  asset: AppAssets.buff,
  accent: AppColors.deepGold,
  blurb:
      'Big, golden and endlessly friendly — often called the golden retriever '
      'of the chicken world.',
  facts: [
    'The Orpington was created in the town of Orpington, England, in the 1880s.',
    'Their thick, fluffy feathers keep them laying right through cold winters.',
    'They are calm enough to become real family pets.',
    'A Buff Orpington is heavy — a rooster can weigh about 4.5 kg!',
  ],
);

const _ameraucana = Breed(
  name: 'Ameraucana',
  origin: 'United States 🇺🇸',
  asset: AppAssets.ameraucana,
  accent: AppColors.teal,
  blurb:
      'The hen that lays sky-blue eggs, with fluffy cheek muffs and a tidy '
      'little beard.',
  facts: [
    'Ameraucanas lay beautiful blue eggs — the colour goes all the way through '
        'the shell.',
    'They were developed in the USA in the 1970s.',
    'The puffy feathers on their cheeks are called “muffs and a beard”.',
    'Their blue eggs taste exactly like white or brown ones — the colour is '
        'just for fun.',
  ],
);

const _brahma = Breed(
  name: 'Brahma',
  origin: 'Asia & America 🌏',
  asset: AppAssets.brahma,
  accent: Color(0xFF8A5A2B),
  blurb:
      'A gentle giant with feathered feet, once proudly called the “King of '
      'All Poultry”.',
  facts: [
    'Brahmas are one of the largest chicken breeds ever kept.',
    'Even their feet are covered in soft feathers, like fluffy boots.',
    'In the 1800s they were the most popular meat bird in America.',
    'Despite their size, Brahmas are famously calm and easy-going.',
  ],
);

// ─────────────────────────────────────────────────────────────────────────
// ISSUES
// ─────────────────────────────────────────────────────────────────────────

const List<Issue> kIssues = [
  Issue(
    number: 1,
    month: 'July',
    year: '2026',
    title: 'The Golden Egg',
    tagline: 'A tiny egg worth more than gold.',
    coverEmoji: '🥚',
    coverColor: AppColors.gold,
    story: Story(
      title: 'Ryaba the Hen',
      origin: 'Russian folk tale',
      flag: '🇷🇺',
      paragraphs: [
        'Once there lived an old man and an old woman, and they kept a little '
            'speckled hen named Ryaba.',
        'One morning Ryaba laid an egg — but it was no ordinary egg. It gleamed '
            'bright and golden, warm as the summer sun.',
        'The old man beat it and beat it, but he could not break it. The old '
            'woman beat it and beat it, but she could not break it either.',
        'Then a little grey mouse scurried by. She flicked her tail, the egg '
            'rolled to the edge of the table and — crack! — it broke upon the '
            'floor.',
        'The old man wept and the old woman wept. But Ryaba clucked softly: '
            '“Do not cry, grandfather; do not cry, grandmother. I shall lay you '
            'a new egg — not a golden one, but a good and simple one.”',
        'And so she did — and the little house was happy once more.',
      ],
      moral: 'The plain, everyday gifts are the ones that truly feed us.',
    ),
    facts: [
      'Chickens can recognise more than 100 different faces — hens and people alike.',
      'A mother hen turns her eggs almost 50 times a day while they grow.',
      'Hens softly cluck to their chicks even before the eggs have hatched.',
      'The heaviest chicken egg on record weighed nearly 340 grams!',
    ],
    breed: _leghorn,
    comic: Comic(
      title: 'The Egg Who Wanted to Fly',
      panels: [
        ComicPanel('🥚', 'Little Egg watched the birds and sighed, “I wish I '
            'could fly too.”'),
        ComicPanel('🪶', 'The wind gave him two feather-soft wings. “Try,” it '
            'whispered.'),
        ComicPanel('💨', 'He wobbled, he tumbled… and then — up he went!'),
        ComicPanel('🌤️', '“Look at me!” he cheered, soaring over the coop.'),
        ComicPanel('🐣', 'And when he finally landed, out hatched the bravest '
            'little chick of all.'),
      ],
    ),
    recipe: Recipe(
      title: 'Sunshine Egg-in-a-Basket',
      subtitle: 'A golden breakfast fit for Ryaba herself.',
      emoji: '🍳',
      minutes: 10,
      difficulty: 'Easy',
      ingredients: [
        '1 slice of bread',
        '1 egg',
        'A little butter',
        'A pinch of salt',
      ],
      steps: [
        'Ask a grown-up to help with the stove.',
        'Cut a round hole in the middle of the bread with a cup.',
        'Butter the bread and place it in a warm pan.',
        'Crack the egg gently into the hole.',
        'Cook until the white is set, then flip for a moment.',
        'Sprinkle a pinch of salt and enjoy your sunny basket!',
      ],
      tip: 'Save the little bread circle and toast it for dipping.',
    ),
    wordSearch: WordSearch(
      title: 'Find the Golden Words',
      words: ['RYABA', 'HEN', 'EGG', 'GOLD', 'MOUSE', 'NEST', 'HOUSE', 'WHEAT'],
    ),
    quiz: Quiz(
      title: 'Ryaba Quiz',
      questions: [
        QuizQuestion('What colour was Ryaba’s special egg?',
            ['Silver', 'Golden', 'Blue'], 1),
        QuizQuestion('Who finally broke the egg?',
            ['The old man', 'A little mouse', 'The wind'], 1),
        QuizQuestion('What did Ryaba promise at the end?',
            ['A new golden egg', 'A simple, ordinary egg', 'To fly away'], 1),
        QuizQuestion('Which country does this tale come from?',
            ['Italy', 'Japan', 'Russia'], 2),
      ],
    ),
  ),
  Issue(
    number: 2,
    month: 'August',
    year: '2026',
    title: 'The Sky Is Falling!',
    tagline: 'One little acorn, one enormous fuss.',
    coverEmoji: '🌰',
    coverColor: AppColors.teal,
    story: Story(
      title: 'Henny Penny',
      origin: 'English folk tale',
      flag: '🇬🇧',
      paragraphs: [
        'One fine day Henny Penny was scratching for corn when — plop! — an '
            'acorn fell right on her head.',
        '“Goodness gracious me!” she cried. “The sky is falling! I must go and '
            'tell the king at once.”',
        'Along the way she met Cocky Locky, Ducky Lucky, Goosey Loosey and '
            'Turkey Lurkey, and they all hurried after her to warn the king.',
        'But who should they meet but sly Foxy Loxy. “Come,” said the fox, “I '
            'know a short cut to the palace.” And he led them toward his den.',
        'Clever Henny Penny felt the trick just in time and flapped away home, '
            'safe and sound.',
        'And she never did find out that it was only a little acorn all along.',
      ],
      moral: 'Do not lose your head over one small acorn.',
    ),
    facts: [
      'Chickens “talk” using more than 24 different sounds, each with its own meaning.',
      'They give a special warning call for danger from above, and another for the ground.',
      'A chicken’s heart beats around 300 times every minute.',
      'Chickens can see more colours than people can — even a little ultraviolet.',
    ],
    breed: _silkie,
    comic: Comic(
      title: 'Acorn Alert!',
      panels: [
        ComicPanel('🌳', 'Under the old oak, Henny Penny took a little nap.'),
        ComicPanel('🌰', 'PLOP! An acorn bounced right off her head.'),
        ComicPanel('😱', '“The sky! The sky is falling!” she squawked.'),
        ComicPanel('🦊', 'A grinning fox offered a “short cut”…'),
        ComicPanel('🏡', '…but wise Henny Penny scurried safely home instead.'),
      ],
    ),
    recipe: Recipe(
      title: 'Falling-Sky Oat Cookies',
      subtitle: 'No acorns required — we promise.',
      emoji: '🍪',
      minutes: 25,
      difficulty: 'Medium',
      ingredients: [
        '1 ripe banana',
        '1 cup of rolled oats',
        'A handful of raisins',
        'A pinch of cinnamon',
      ],
      steps: [
        'Ask a grown-up to set the oven to 180°C (350°F).',
        'Mash the banana in a bowl until smooth.',
        'Stir in the oats, raisins and cinnamon.',
        'Spoon little mounds onto a lined baking tray.',
        'Bake for about 15 minutes until golden.',
        'Let them cool — then catch them before they “fall”!',
      ],
      tip: 'Press each cookie flat with a spoon for a crispier bite.',
    ),
    wordSearch: WordSearch(
      title: 'Sky-High Word Hunt',
      words: ['HENNY', 'PENNY', 'ACORN', 'SKY', 'FOX', 'DUCK', 'GOOSE', 'KING'],
    ),
    quiz: Quiz(
      title: 'Henny Penny Quiz',
      questions: [
        QuizQuestion('What really fell on Henny Penny’s head?',
            ['A raindrop', 'An acorn', 'A star'], 1),
        QuizQuestion('Who did she want to warn?',
            ['The king', 'The farmer', 'Her chicks'], 0),
        QuizQuestion('Who tried to trick the birds with a short cut?',
            ['Foxy Loxy', 'Ducky Lucky', 'Turkey Lurkey'], 0),
        QuizQuestion('How did Henny Penny escape?',
            ['She fought the fox', 'She flew to the moon', 'She hurried home'], 2),
      ],
    ),
  ),
  Issue(
    number: 3,
    month: 'September',
    year: '2026',
    title: 'Who Will Help Me?',
    tagline: 'A little hen, a lot of hard work.',
    coverEmoji: '🌾',
    coverColor: AppColors.deepGold,
    story: Story(
      title: 'The Little Red Hen',
      origin: 'Classic folk tale',
      flag: '🇺🇸',
      paragraphs: [
        'The Little Red Hen found some grains of wheat. “Who will help me plant '
            'the wheat?” she asked.',
        '“Not I,” said the cat. “Not I,” said the dog. “Not I,” said the mouse.',
        '“Then I will do it myself,” said the Little Red Hen. And she did.',
        'She tended the wheat, cut it, carried it to the mill, and baked it into '
            'warm, sweet bread — and at every single step her friends still said, '
            '“Not I.”',
        '“Now who will help me eat the bread?” she asked. “I will!” they all '
            'cried at once.',
        '“Oh no,” said the Little Red Hen. “I planted it, I tended it, I baked '
            'it — and I shall eat it myself.” And she did, every last crumb.',
      ],
      moral: 'Those who share the work deserve to share the reward.',
    ),
    facts: [
      'Chickens are the closest living relatives of the mighty Tyrannosaurus rex.',
      'A hen scratches the ground to uncover seeds and tasty insects.',
      'Chickens have a real “pecking order” — a social rank within every flock.',
      'A happy, well-fed hen can lay an egg almost every day.',
    ],
    breed: _buff,
    comic: Comic(
      title: 'Not I!',
      panels: [
        ComicPanel('🌱', '“Who will help me plant?” asked the Little Red Hen.'),
        ComicPanel('🐱', '“Not I,” yawned the cat.'),
        ComicPanel('🐶', '“Not I,” shrugged the dog.'),
        ComicPanel('🍞', 'So she did it all — and baked warm, golden bread.'),
        ComicPanel('😋', '“Then I shall eat it myself!” And she did.'),
      ],
    ),
    recipe: Recipe(
      title: 'The Little Red Hen’s Honey Bread',
      subtitle: 'From the wheat field to your plate.',
      emoji: '🍞',
      minutes: 40,
      difficulty: 'Medium',
      ingredients: [
        '2 cups of flour',
        '1 cup of warm milk',
        '2 spoons of honey',
        '1 packet of baking powder',
      ],
      steps: [
        'Ask a grown-up to help with the oven, set to 190°C (375°F).',
        'Mix the flour and baking powder in a big bowl.',
        'Pour in the warm milk and honey, and stir into a soft dough.',
        'Shape it into a little round loaf.',
        'Bake for about 25 minutes until golden and hollow-sounding.',
        'Share a slice — with everyone who helped!',
      ],
      tip: 'Brush the top with a little extra honey when it comes out warm.',
    ),
    wordSearch: WordSearch(
      title: 'Harvest Word Search',
      words: ['WHEAT', 'BREAD', 'MILL', 'GRAIN', 'HEN', 'HELP', 'BAKE', 'FLOUR'],
    ),
    quiz: Quiz(
      title: 'Little Red Hen Quiz',
      questions: [
        QuizQuestion('What did the Little Red Hen find?',
            ['Grains of wheat', 'A golden egg', 'A magic bean'], 0),
        QuizQuestion('What did her friends keep saying?',
            ['“Me too!”', '“Not I”', '“Later”'], 1),
        QuizQuestion('Where did she take the wheat to be ground?',
            ['The mill', 'The market', 'The river'], 0),
        QuizQuestion('Who ate the finished bread?',
            ['Everyone', 'The cat', 'The Little Red Hen'], 2),
      ],
    ),
  ),
  Issue(
    number: 4,
    month: 'October',
    year: '2026',
    title: 'All That Glitters',
    tagline: 'When one golden egg a day is not enough…',
    coverEmoji: '✨',
    coverColor: AppColors.cherry,
    story: Story(
      title: 'The Hen and the Golden Eggs',
      origin: 'Aesop’s fable',
      flag: '🏛️',
      paragraphs: [
        'A countryman owned a wonderful hen that laid one shining golden egg '
            'every single day.',
        'He grew rich — but riches only made him greedy. “Why wait for one egg a '
            'day?” he thought. “There must be a great lump of gold inside her.”',
        'So he took the hen and looked inside. But she was just like any other '
            'hen — and now there would be no golden eggs at all.',
        'The foolish man had lost both his treasure and his little golden hen.',
        'Ever after he wished he had been happy with one small gift each day.',
      ],
      moral: 'Greed for more often destroys the good we already have.',
    ),
    facts: [
      'Egg shells get their colour from pigments added in the last hours before laying.',
      'A single hen can lay eggs in white, brown, cream, pink, green or blue — '
          'depending on her breed.',
      'It takes a hen about 24 to 26 hours to make one egg.',
      'Eggshells are covered in thousands of tiny pores so the chick can breathe.',
    ],
    breed: _ameraucana,
    comic: Comic(
      title: 'One Egg a Day',
      panels: [
        ComicPanel('🐔', 'Each morning the hen laid one shining golden egg.'),
        ComicPanel('🤑', 'The farmer grew greedy. “I want them ALL now!”'),
        ComicPanel('🔎', 'He searched for a lump of gold inside…'),
        ComicPanel('🪺', '…but found only an ordinary, empty nest.'),
        ComicPanel('😔', 'And the golden eggs never came again.'),
      ],
    ),
    recipe: Recipe(
      title: 'Golden Cornbread Coins',
      subtitle: 'Little rounds of treasure you can actually eat.',
      emoji: '🌽',
      minutes: 30,
      difficulty: 'Medium',
      ingredients: [
        '1 cup of cornmeal',
        '1 cup of flour',
        '1 cup of milk',
        '1 egg and 2 spoons of honey',
      ],
      steps: [
        'Ask a grown-up to heat the oven to 200°C (400°F).',
        'Whisk the milk, egg and honey together.',
        'Stir in the cornmeal and flour until smooth.',
        'Spoon little coin-sized rounds onto a lined tray.',
        'Bake for about 15 minutes until golden.',
        'Stack your “gold coins” — but remember to share!',
      ],
      tip: 'A tiny pinch of salt makes the sweetness shine.',
    ),
    wordSearch: WordSearch(
      title: 'Treasure Word Search',
      words: ['GOLD', 'GREED', 'EGG', 'HEN', 'FARM', 'WISE', 'RICH', 'DAILY'],
    ),
    quiz: Quiz(
      title: 'Golden Eggs Quiz',
      questions: [
        QuizQuestion('How many golden eggs did the hen lay each day?',
            ['One', 'Three', 'A dozen'], 0),
        QuizQuestion('What feeling led the farmer astray?',
            ['Kindness', 'Greed', 'Fear'], 1),
        QuizQuestion('What did he find inside the hen?',
            ['A lump of gold', 'Nothing special', 'Another egg'], 1),
        QuizQuestion('What is the moral of this fable?',
            ['Save your gold', 'Be happy with what you have', 'Wake up early'], 1),
      ],
    ),
  ),
  Issue(
    number: 5,
    month: 'November',
    year: '2026',
    title: 'The Rooster & the Sun',
    tagline: 'How a brave crow called back the dawn.',
    coverEmoji: '🌅',
    coverColor: AppColors.folkBlue,
    story: Story(
      title: 'The Rooster and the Sun',
      origin: 'Japanese myth',
      flag: '🇯🇵',
      paragraphs: [
        'Long ago the sun goddess Amaterasu, sad and angry, hid herself inside '
            'a cave of stone. At once the whole world fell into cold darkness.',
        'The other gods gathered to make a plan. They set the long-crowing '
            'roosters before the cave, and the birds crowed and crowed to call '
            'back the dawn.',
        'They hung a shining mirror and glittering jewels on a great tree, and a '
            'goddess danced until everyone roared with laughter.',
        'Curious about the merriment, Amaterasu peeked out — and saw her own '
            'radiant light shining in the mirror.',
        'The gods gently drew her out, and warmth and daylight flooded back '
            'across the world.',
        'And ever since, the rooster crows each morning to greet the returning '
            'sun.',
      ],
      moral: 'Even the smallest voice can help call the light back.',
    ),
    facts: [
      'Roosters really do crow at dawn — but also throughout the day.',
      'A rooster tips his head back to crow so he can open his beak as wide as possible.',
      'Chickens have an inner clock that senses the coming sunrise before we do.',
      'Some long-crowing breeds can hold a single crow for many seconds.',
    ],
    breed: _brahma,
    comic: Comic(
      title: 'Wake the Sun',
      panels: [
        ComicPanel('🌑', 'The sun hid away, and the world went dark and cold.'),
        ComicPanel('🐓', 'So every rooster crowed with all its might.'),
        ComicPanel('🪞', 'A mirror sparkled; a joyful dance began.'),
        ComicPanel('👀', 'Curious, the sun goddess peeked out to look…'),
        ComicPanel('🌅', '…and daylight rushed warmly back into the world.'),
      ],
    ),
    recipe: Recipe(
      title: 'Sunrise Rice Balls',
      subtitle: 'Little suns you can hold in your hand.',
      emoji: '🍙',
      minutes: 20,
      difficulty: 'Easy',
      ingredients: [
        '2 cups of cooked rice (cooled a little)',
        'A small bowl of water',
        'A pinch of salt',
        'A sheet of dried seaweed (optional)',
      ],
      steps: [
        'Wet your clean hands so the rice will not stick.',
        'Scoop a small handful of warm rice into your palm.',
        'Gently press it into a round or triangle shape.',
        'Sprinkle on a tiny pinch of salt.',
        'Wrap a strip of seaweed around the bottom if you like.',
        'Line them up like little rising suns and enjoy!',
      ],
      tip: 'Ask a grown-up to help with the cooked rice — it can be hot.',
    ),
    wordSearch: WordSearch(
      title: 'Dawn Word Search',
      words: ['SUN', 'CAVE', 'ROOSTER', 'DAWN', 'LIGHT', 'MIRROR', 'CROW', 'DANCE'],
    ),
    quiz: Quiz(
      title: 'Rooster & Sun Quiz',
      questions: [
        QuizQuestion('Where did the sun goddess hide?',
            ['In a cave', 'Behind a cloud', 'Under the sea'], 0),
        QuizQuestion('Which birds helped call back the dawn?',
            ['Owls', 'Roosters', 'Swans'], 1),
        QuizQuestion('What did the goddess see that drew her out?',
            ['Her light in a mirror', 'A golden egg', 'A rainbow'], 0),
        QuizQuestion('When does the rooster crow to greet the sun?',
            ['At midnight', 'Each morning', 'Never again'], 1),
      ],
    ),
  ),
];

Issue issueByNumber(int n) =>
    kIssues.firstWhere((i) => i.number == n, orElse: () => kIssues.first);
