//
//  CPTrendingShowcaseViewController.swift
//  Coderpursue
//
//  Created by WengHengcong on 3/10/16.
//  Copyright © 2016 JungleSong. All rights reserved.
//

import UIKit
import Moya
import Foundation
import MJRefresh
import ObjectMapper

class CPTrendingShowcaseViewController: CPBaseViewController {

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var showcaseInfoV: CPShowcaseInfoView!
    
    // 顶部刷新
    let header = MJRefreshNormalHeader()
    
    var showcase:ObjShowcase!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tsc_setupTableView()
        tsc_updateContentView()
        tsc_getShowcaseRequest()
        self.title = showcase.slug

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func leftItemAction(_ sender: UIButton?) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func tsc_setupTableView() {
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.separatorStyle = .none
        self.tableView.backgroundColor = UIColor.viewBackgroundColor()
        self.automaticallyAdjustsScrollViewInsets = false
        
        // 下拉刷新
        header.setTitle("Pull down to refresh", for: .idle)
        header.setTitle("Release to refresh", for: .pulling)
        header.setTitle("Loading ...", for: .refreshing)
        header.setRefreshingTarget(self, refreshingAction: #selector(CPTrendingShowcaseViewController.headerRefresh))
        // 现在的版本要用mj_header
        self.tableView.mj_header = header

    }
    // 顶部刷新
    func headerRefresh(){
        print("下拉刷新")

    }

    func tsc_updateContentView() {
        showcaseInfoV.showcase = self.showcase
        self.tableView.reloadData()
    }
    
    func tsc_getShowcaseRequest(){
    
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        Provider.sharedProvider.request(.trendingShowcase(showcase:showcase.slug!) ) { (result) -> () in
            
            var message = "No data to show"
            
            self.tableView.mj_header.endRefreshing()
            
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            
            switch result {
            case let .success(response):
                
                do {
                    if let result:ObjShowcase = Mapper<ObjShowcase>().map(JSONObject:try response.mapJSON() ) {
                        
                        if(self.showcase!.repositories != nil){
                            self.showcase!.repositories!.removeAll()
                        }else{
                            
                        }
                        self.showcase!.repositories = result.repositories!
                        self.tsc_updateContentView()

                    } else {
                        
                    }

                } catch {
                    CPGlobalHelper.sharedInstance.showError(message, view: self.view)
                }
            case let .failure(error):
                guard let error = error as? CustomStringConvertible else {
                    break
                }
                message = error.description
                CPGlobalHelper.sharedInstance.showError(message, view: self.view)
                
            }
            
        }

    }
}


extension CPTrendingShowcaseViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if(showcase.repositories == nil){
            return 0
        }
        
        let reposCount = showcase.repositories!.count
        return reposCount

    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let row = (indexPath as NSIndexPath).row
        
        let cellId = "CPTrendingRepoCellIdentifier"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellId) as? CPTrendingRepoCell
        if cell == nil {
            cell = (CPTrendingRepoCell.cellFromNibNamed("CPTrendingRepoCell") as! CPTrendingRepoCell)
        }
        
        //handle line in cell
        if row == 0 {
            cell!.topline = true
        }
        if (row == showcase.repositories!.count-1) {
            cell!.fullline = true
        }else {
            cell!.fullline = false
        }
        
        let repos = self.showcase.repositories![row]
        cell!.objRepos = repos
        
        return cell!;
            
    }
    
}

extension CPTrendingShowcaseViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
 
        return 85
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        let repos = self.showcase.repositories![(indexPath as NSIndexPath).row]
        self.performSegue(withIdentifier: SegueTrendingShowRepositoryDetail, sender: repos)

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if (segue.identifier == SegueTrendingShowRepositoryDetail){
            
            let reposVC = segue.destination as! CPTrendingRepositoryViewController
            reposVC.hidesBottomBarWhenPushed = true
            let repos = sender as? ObjRepos
            if(repos != nil){
                reposVC.repos = repos
            }
            
        }
        
    }
    
}

