import { select } from "@inquirer/prompts";
import { MersenneTwister } from "./mersenne";

let n = new MersenneTwister(1); // this should be a number hash instead

type PlayerState = {
  seed: number;
  past: PastRun[];
  current?: CurrentRun; // each current run starts from seed + length of past runs
};

type PastRun = {
  score: number;
  blames: number[];
  party: number;
  superpowers: number[];
  challenges: number[];
  duration: number;
};

type Moment = {
  date: string;
  time: string;
  weekday: "Mo" | "Tu" | "We" | "Th" | "Fr" | "Sa" | "Su";
};

type RunContext = {
  start: string;
  now: Moment;
  birthday: string;

  days_: number; // _ suffix to indicate dupe source of truth, but here for convenience
};

type Effect = {
  // number = relative, [number] = absolute
  popularity: number | [setTo: number];
  // ...
};

type EffectFn = (days: number, ctx: RunContext) => Effect;

type ActiveEffect = {
  name: string; // as short as reasonably possible
  start: string; // ISO
  days: number;
  effectFn: EffectFn;
  shouldRemove: (ctx: RunContext, effect: Effect) => boolean; // rubbish collection
};

type CurrentRun = PastRun & {
  stateSeed: number;
  context: RunContext;
  activeEffects: ActiveEffect[];
};

type Choice = {
  name: string;
  value: ActiveEffect[];
  description: string;
};

type Question = {
  message: string;
  choices: Choice[];
};

type GenerateNextQuestion = (run: CurrentRun) => Question;

async function startGame() {
  console.log("");

  const answer = await select({
    message: "What would you like to do?",
    choices: [
      {
        name: "a",
        value: "a",
        description: "...some desc about a...",
      },
      {
        name: "b",
        value: "b",
        description: "...some desc about b...",
      },
    ],
  });

  console.log(`You selected: ${answer}`);
}

startGame();
