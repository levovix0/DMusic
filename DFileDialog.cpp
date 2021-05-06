#include "DFileDialog.hpp"
#include <QFile>
#include <fstream>

DFileDialog::DFileDialog(QObject *parent) : QObject(parent)
{

}

bool DFileDialog::available()
{
#ifdef Q_OS_LINUX
  return QFile::exists("filedialog");
#else
  return false;
#endif
}

QString DFileDialog::open(QString title, QString opens, QString cancels, QString filter, QString filterName)
{
#ifdef Q_OS_LINUX
  auto command = QString("./filedialog \"%1\" \"%2\" \"%3\" \"%4\" \"%5\"").arg(title, opens, cancels, filter, filterName);
  FILE* fp = popen(command.toUtf8().data(), "r");
  char* line;
  size_t len;
  getline(&line, &len, fp);
  pclose(fp);
  return QString::fromUtf8(line, strlen(line) - 1);
#else
  return "";
#endif
}

QString DFileDialog::sellect(QString title, QString filter, QString filterName)
{
  return open(title, tr("Sellect"), tr("Cancel"), filter, filterName);
}
