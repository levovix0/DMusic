#include "DFileDialog.hpp"
#include <fstream>
#include <QFile>
#include <QFileDialog>
#include <QRegExpValidator>

DFileDialog::DFileDialog(QObject *parent) : QObject(parent)
{

}

namespace {
	void setFileDialogFilter(QFileDialog& dlg, QString const& filter) {
		if (filter.contains(QLatin1String("*"))) {
			QString qtFilter = filter;
			dlg.setNameFilter(qtFilter.replace(QLatin1Char('|'), QLatin1Char('\n')));
		} else if (!filter.isEmpty()) {
			dlg.setMimeTypeFilters(filter.trimmed().split(QLatin1Char(' ')));
		}
	}
}

QUrl DFileDialog::openFile(QString filter, QString title)
{
	QFileDialog dlg;
	dlg.setAcceptMode(QFileDialog::AcceptOpen);
	dlg.setFileMode(QFileDialog::AnyFile);
	dlg.setFileMode(QFileDialog::ExistingFile);
	setFileDialogFilter(dlg, filter);
	dlg.setWindowTitle(title);

	return dlg.exec()? dlg.selectedUrls().at(0) : QUrl{};
}

QList<QUrl> DFileDialog::openFiles(QString filter, QString title)
{
	QFileDialog dlg;
	dlg.setAcceptMode(QFileDialog::AcceptOpen);
	dlg.setFileMode(QFileDialog::AnyFile);
	dlg.setFileMode(QFileDialog::ExistingFiles);
	setFileDialogFilter(dlg, filter);
	dlg.setWindowTitle(title);

	return dlg.exec()? dlg.selectedUrls() : QList<QUrl>{};
}

bool DFileDialog::checkFilter(QString file, QString filter)
{
	auto filters = filter.split("|");
	QStringList masks;

	for (auto& f : filters) {
		f.remove(0, f.indexOf("(") + 1);
		f.truncate(f.indexOf(")"));
		masks.append(f.split(" "));
	}

	for (auto& mask : masks) {
		mask.replace(".", "\\.").replace("*", ".*").replace("?", ".");
		if (QRegExp("^" + mask + "$").exactMatch(file)) return true;
	}
	return false;
}