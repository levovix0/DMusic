#include "SearchHistory.hpp"
#include "Config.hpp"
#include "nimfs.hpp"

SearchHistory* SearchHistory::instance = new SearchHistory;

SearchHistory::SearchHistory(QObject *parent) : QAbstractListModel(parent)
{
  load();
}

SearchHistory* SearchHistory::qmlInstance(QQmlEngine*, QJSEngine*)
{
  return instance;
}

int SearchHistory::rowCount(const QModelIndex&) const
{
  return _history.length();
}

QVariant SearchHistory::data(const QModelIndex& index, int) const
{
  if (index.row() < 0 || index.row() >= _history.length()) return QVariant::Invalid;
  QVariant res;
  res.setValue(_history[index.row()]);
  return res;
}

QHash<int, QByteArray> SearchHistory::roleNames() const
{
  static QHash<int, QByteArray>* pHash = nullptr;
  if (!pHash) {
    pHash = new QHash<int, QByteArray>;
    (*pHash)[Qt::UserRole + 1] = "element";
  }
  return *pHash;
}

void SearchHistory::savePromit(QString promit)
{
  auto p = std::find(_history.begin(), _history.end(), promit);
  if (p == _history.end()) { // not in history
    _history.push_front(promit);
    if (_history.length() > maxLenght) {
       _history.erase(_history.begin() + maxLenght, _history.end());
    }
  } else {
    _history.swapItemsAt(-(_history.begin() - p), 0);
  }
  save();
}

void SearchHistory::load()
{
  _history.clear();
  if (!fileExists(Config::dataDir().sub("searchHistory.txt"))) return;
  QFile f(Config::dataDir().sub("searchHistory.txt"));

  f.open(QFile::ReadOnly);
  while (!f.atEnd()) {
    auto line = QString::fromUtf8(f.readLine());
    line.replace("\n", "");
    if (line.isEmpty()) continue;
    _history.append(line);
  }
  f.close();
}

void SearchHistory::save()
{
  QFile f(Config::dataDir().sub("searchHistory.txt"));

  f.open(QFile::Truncate | QFile::WriteOnly);
  for (auto&& x : _history) {
    f.write(x.toUtf8());
    f.write("\n");
  }
  f.close();
}
