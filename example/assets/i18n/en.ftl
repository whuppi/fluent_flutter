# The complete base locale — every message the demo touches.
app-title = fluent_flutter demo
greet = Hello, { $name }!
items = { $count ->
    [one] one item
   *[other] { $count } items
}
price = Total: { NUMBER($amount, style: "currency", currency: "USD") }
today = Today is { DATETIME($date, dateStyle: "medium") }
banner = Read <bold>the guide</bold> — then <a>tap here</a>!
login = Sign in
    .title = Welcome back
only-english = This string exists only in English — you are seeing the fallback chain at work.
chain-label = Loaded chain
