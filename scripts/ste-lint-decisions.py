import re, sys, json, glob, os

MARKETING = ["seamless","seamlessly","robust","powerful","cutting-edge","effortless","effortlessly",
 "world-class","next-generation","revolutionary","blazing","lightning-fast","elegant","delightful",
 "turnkey","best-in-class","state-of-the-art","game-changing","first-class","battle-tested",
 "enterprise-grade","supercharge","unlock","unleash","empower","empowers"]
BANNED = ["begin","begins","commence","commences","initiate","initiates","originate",
 "utilize","utilizes","utilizing","leverage","leverages","leveraging","facilitate","facilitates",
 "ensure","ensures","ensuring","prior to","subsequent to","obtain","obtains","acquire","acquires",
 "demonstrate","demonstrates","additionally","furthermore","moreover","comprehensive","comprehensively",
 "utilization","aforementioned","henceforth","therein","whilst","amongst","numerous","myriad","plethora",
 "in order to","a variety of","in the event that","due to the fact that","it is important to note"]
PHRASAL = ["spin up","spin down","reach out","dive into","dives into","diving into","kick off","kicks off",
 "roll out","rolls out","tear down","ramp up","circle back","drill down","spun up","reaching out"]
MODAL_HEDGE = ["it is important to note","it should be noted","it is worth noting","please note that",
 "as mentioned","as noted above"]
BE = r"(?:am|is|are|was|were|be|been|being)"
PP_IRREG = r"(?:done|made|sent|read|built|kept|held|set|put|run|written|shown|given|taken|found|got|gotten|seen|known|thrown|drawn)"

def strip_code(t):
 t = re.sub(r"```.*?```", " ", t, flags=re.S)
 t = re.sub(r"`[^`]*`", " ", t)
 return t

def sentences(text):
 out = []
 for line in text.split("\n"):
  s = line.strip()
  if not s: continue
  s = re.sub(r"^\s*#{1,6}\s*", "", s)
  s = re.sub(r"^\s*(?:[-*+]|\d+[.)])\s+", "", s)
  if not s: continue
  parts = re.split(r"(?<=[.!?:])\s+(?=[A-Z0-9\"'\-])", s)
  for p in parts:
   p = p.strip()
   if p: out.append(p)
 return out

def wc(s):
 return len([w for w in re.findall(r"[A-Za-z0-9][A-Za-z0-9'\-/]*", s)])

def count_ci(text, phrases):
 n = 0; hits = []
 low = text.lower()
 for ph in phrases:
  for m in re.finditer(r"(?<![a-z])" + re.escape(ph) + r"(?![a-z])", low):
   n += 1; hits.append(ph)
 return n, hits

def lint(text):
 raw = text
 text = strip_code(text)
 words = wc(text)
 sents = sentences(text)
 longs = [(wc(s), s) for s in sents if wc(s) > 25]
 v = {}
 v["long_sentence(>25w)"] = len(longs)
 longs20 = [(wc(s), s) for s in sents if wc(s) > 20]
 v["long_sentence_proc(>20w)"] = len(longs20)
 v["semicolon"] = text.count(";")
 # A contraction is a closed set. `'s` is possessive far more often
 # than it is a contraction ("the model's weights"), so count `'s`
 # only after a stem that really does contract. Rewriting a
 # possessive would make the English worse, not simpler.
 v["contraction"] = (
  len(re.findall(r"\b\w+['\u2019](?:t|re|ve|ll|m)\b", text))
  + len(re.findall(r"\b(?:it|that|there|here|what|let|he|she|who|where|how)['\u2019]s\b", text, re.I))
  + len(re.findall(r"\b(?:i|you|we|they|he|she|it)['\u2019]d\b", text, re.I))
 )
 v["passive_voice"] = len(re.findall(rf"\b{BE}\s+(?:\w+ed|{PP_IRREG})\b", text, re.I))
 v["ing_main_verb"] = len(re.findall(rf"\b{BE}\s+\w+ing\b", text, re.I))
 v["nominalization"] = len(re.findall(r"\b(?:perform(?:s|ed)?|conduct(?:s|ed)?|provide(?:s|d)?|carry out|carries out|make use of|makes use of)\b", text, re.I)) + len(re.findall(r"\b\w{4,}(?:tion|ment|ance|ence)\s+of\b", text, re.I))
 v["phrasal_verb"], _ = count_ci(text, PHRASAL)
 v["banned_word"], bh = count_ci(text, BANNED)
 v["marketing_adjective"], mh = count_ci(text, MARKETING)
 v["modal_hedge"], _ = count_ci(text, MODAL_HEDGE)
 # Split paragraphs from the code-stripped text, not the raw text. A
 # fenced block that holds a blank line otherwise splits into pieces
 # with unbalanced fences, strip_code cannot remove them, and every
 # line of code counts as a sentence. Code is not prose.
 # Count sentences of prose only. A list item and a table row are
 # not sentences of a paragraph. STE asks a writer to prefer a list
 # over dense prose, so counting each bullet would penalise the
 # structure the standard recommends.
 def prose_only(p):
  keep = [l for l in p.split("\n")
          if not re.match(r"^\s*(?:[-*+]|\d+[.)])\s", l) and not l.strip().startswith("|")]
  return "\n".join(keep)
 paras = [p for p in re.split(r"\n\s*\n", text) if p.strip()]
 v["long_paragraph(>6s)"] = sum(1 for p in paras if len(sentences(prose_only(p))) > 6)
 em = raw.count("\u2014") + raw.count("\u2013")
 total = sum(v.values())
 per100 = {k: round(x*100.0/words, 2) for k, x in v.items()}
 return {
  "words": words, "sentences": len(sents),
  "violations": v, "total": total,
  "total_per100w": round(total*100.0/words, 2),
  "em_dash(slop-marker)": em,
  "longest_sentence_words": (max(longs)[0] if longs else max((wc(s) for s in sents), default=0)),
  "sample_marketing": list(dict.fromkeys(mh))[:6],
  "sample_banned": list(dict.fromkeys(bh))[:6],
 }

if __name__ == "__main__":
 import sys as _sys
 _THRESHOLD = float(_sys.argv[1]) if len(_sys.argv) > 1 and _sys.argv[1].isdigit() else 2.5
 _fail = 0
 for f in _sys.argv[1:]:
  try:
   with open(f) as fh: r=lint(fh.read())
  except OSError:
   continue
  flag = 'FAIL' if r['total_per100w'] > _THRESHOLD else 'ok'
  # Each RFD is a folder holding README.md, so the basename alone
  # names every file the same. Show the folder instead.
  label = os.path.basename(f)
  if label == 'README.md':
   label = os.path.basename(os.path.dirname(os.path.abspath(f)))
  print(f"{flag} {label:44} per100w={r['total_per100w']:6.2f} total={r['total']:3d}")
  if r['total_per100w'] > _THRESHOLD: _fail = 1
 _sys.exit(_fail)

 files = sys.argv[1:] or []
 if not files:
  print(json.dumps(lint(sys.stdin.read()), indent=2)); sys.exit(0)
 exp = []
 for f in files: exp += sorted(glob.glob(f)) if any(c in f for c in "*?[") else [f]
 for f in exp:
  with open(f) as fh: r = lint(fh.read())
  print(f"{os.path.basename(f):32} words={r['words']:4d} total={r['total']:3d} per100w={r['total_per100w']:6.2f} em_dash={r['em_dash(slop-marker)']:2d}")