//
//  IgnoredKeywordsViewController.swift
//  Sileo
//
//  Created by Sileo Team on 1/12/26.
//  Copyright © 2026 Sileo Team. All rights reserved.
//

import UIKit

class IgnoredKeywordsViewController: SileoTableViewController {
    
    private var ignoredKeywords: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = ""
        self.navigationItem.largeTitleDisplayMode = .never
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addKeyword))
        
        loadKeywords()
        
        let headerView = UIView(frame: .zero)
        
        let titleLabel = UILabel()
        titleLabel.text = String(localizationKey: "Ignored_Keywords")
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .sileoLabel
        
        let descriptionLabel = UILabel()
        descriptionLabel.text = String(localizationKey: "Ignored_Keywords_Description")
        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = UIFont.systemFont(ofSize: 13)
        descriptionLabel.textColor = .gray
        descriptionLabel.textAlignment = .center
        
        headerView.addSubview(titleLabel)
        headerView.addSubview(descriptionLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 15),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -15),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 15),
            descriptionLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -15),
            descriptionLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -10)
        ])
        
        // Calculate height
        let width = UIScreen.main.bounds.width - 30
        let titleSize = titleLabel.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        let descSize = descriptionLabel.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        headerView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: titleSize.height + descSize.height + 24)
        
        tableView.tableHeaderView = headerView
        
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .sileoBackgroundColor
        tableView.separatorColor = .sileoSeparatorColor
    }
    
    private func loadKeywords() {
        ignoredKeywords = UserDefaults.standard.stringArray(forKey: "IgnoredKeywords") ?? []
        tableView.reloadData()
    }
    
    private func saveKeywords() {
        UserDefaults.standard.set(ignoredKeywords, forKey: "IgnoredKeywords")
        NotificationCenter.default.post(name: Notification.Name("IgnoredKeywordsChanged"), object: nil)
    }
    
    @objc private func addKeyword() {
        let alert = UIAlertController(title: String(localizationKey: "Add_Ignored_Keyword"), message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = String(localizationKey: "Keyword")
        }
        
        let addAction = UIAlertAction(title: String(localizationKey: "Add"), style: .default) { [weak self] _ in
            guard let self = self, let text = alert.textFields?.first?.text, !text.isEmpty else { return }
            if !self.ignoredKeywords.contains(text) {
                self.ignoredKeywords.append(text)
                self.saveKeywords()
                self.tableView.insertRows(at: [IndexPath(row: self.ignoredKeywords.count - 1, section: 0)], with: .automatic)
            }
        }
        
        let cancelAction = UIAlertAction(title: String(localizationKey: "Cancel"), style: .cancel, handler: nil)
        
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ignoredKeywords.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "KeywordCell") ?? UITableViewCell(style: .default, reuseIdentifier: "KeywordCell")
        cell.textLabel?.text = ignoredKeywords[indexPath.row]
        cell.backgroundColor = .clear
        cell.textLabel?.textColor = .sileoLabel
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            ignoredKeywords.remove(at: indexPath.row)
            saveKeywords()
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
