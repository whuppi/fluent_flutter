# Partial on purpose: `banner` and `only-english` are missing, so the
# chain falls back to English for them.
app-title = fluent_flutter Demo
greet = Hallo, { $name }!
items = { $count ->
    [one] ein Element
   *[other] { $count } Elemente
}
price = Summe: { NUMBER($amount, style: "currency", currency: "EUR") }
today = Heute ist { DATETIME($date, dateStyle: "medium") }
login = Anmelden
    .title = Willkommen zurück
chain-label = Geladene Kette
