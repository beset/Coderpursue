//
//  CPSearchViewController.swift
//  Coderpursue
//
//  Created by WengHengcong on 4/6/16.
//  Copyright © 2016 JungleSong. All rights reserved.
//

import UIKit
import Moya
import Foundation
import MJRefresh
import ObjectMapper

class CPSearchViewController: CPBaseViewController {

    var pageType:TrendingViewPageType = .Repos
    var searchPlacehoder = "Search"
    
    var searchFilterH:CGFloat = 290
    lazy var searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: ScreenSize.ScreenWidth-70, height: 20))
    var tableView = UITableView()
    var maskView = UIView()
    let header = MJRefreshNormalHeader()
    let footer = MJRefreshAutoNormalFooter()
    
    var languageArr:[String]?
    var sortArr:[String]?
    var searchFilterView:CPSearchFilterView?
    
    var paraUser:ParaSearchUser = ParaSearchUser.init()
    var paraRepos:ParaSearchRepos = ParaSearchRepos.init()
    
    var usersData:[ObjUser]! = []
    var reposData:[ObjRepos]! = []
    
    var totalItemCount:Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        svc_initNavBar()
        svc_initSearchFilterView()
        svc_setupTableView()
        svc_setupMaskView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func svc_initNavBar() {
        
        searchBar.placeholder = searchPlacehoder
        searchBar.delegate = self        
        let rightNavBarButton = UIBarButtonItem(customView:searchBar)
        self.navigationItem.rightBarButtonItem = rightNavBarButton
        
        self.view.backgroundColor = UIColor.white
    }
    
    func svc_initSearchFilterView() {
        
        if let path = Bundle.main.path(forResource: "CPLanguage", ofType: "plist") {
            languageArr = NSArray(contentsOfFile: path)! as? [String]
        }
        
        if  pageType == .Repos {
            sortArr = ["Best match","Most stars","Fewest stars","Most forks","Fewest forks","Recently updated","Leaest recently updated"]
        }else{
            sortArr = ["Best match","Most followers","Fewest followers","Most recently joined","Leaest recently joined","Most repositories ","Fewest repositories"]
        }
        searchFilterView = CPSearchFilterView()
        searchFilterView?.frame = CGRect(x: 0, y: topOffset, width: self.view.width, height: searchFilterH)
        searchFilterView?.searchParaDelegate = self
        searchFilterView?.filterPara = ["Language","Sort"]
        searchFilterView?.filterData = [languageArr!,sortArr!]
        searchFilterView?.sfv_customView()
        self.view.addSubview(searchFilterView!)
        
    }
    
    override func leftItemAction(_ sender: UIButton?) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    func svc_setupTableView() {
        
        tableView.frame = CGRect(x: 0, y: (searchFilterView?.bottom)! ,width: self.view.width, height: self.view.height-searchFilterView!.bottom)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.viewBackgroundColor()
        automaticallyAdjustsScrollViewInsets = false
        self.view.insertSubview(tableView, belowSubview: self.searchFilterView!)
        
        // 下拉刷新
        header.setTitle("Pull down to refresh", for: .idle)
        header.setTitle("Release to refresh", for: .pulling)
        header.setTitle("Loading ...", for: .refreshing)
        header.setRefreshingTarget(self, refreshingAction: #selector(CPSearchViewController.svc_headerRefresh) )
        header.isHidden = true
        self.tableView.mj_header = header
        
        // 上拉刷新
        footer.setTitle("Click or drag up to refresh", for: .idle)
        footer.setTitle("Loading more ...", for: .pulling)
        footer.setTitle("No more data", for: .noMoreData)
        footer.setRefreshingTarget(self, refreshingAction: #selector(CPSearchViewController.svc_footerRefresh) )
        footer.isRefreshingTitleHidden = true
        footer.isHidden = true
        self.tableView.mj_footer = footer
    }

    func svc_setupMaskView(){
        maskView.frame = CGRect(x: 0, y: searchFilterH+topOffset, width: self.view.width, height: self.view.height-searchFilterH-topOffset)
        maskView.backgroundColor = UIColor.hexStr("#666666", alpha: 0.3)
        maskView.isHidden = true

        self.view.insertSubview(maskView, aboveSubview: tableView)
    }

    
    func svc_headerRefresh() {
        
        if svc_checkSearchKeywordIsNull() {
            return
        }
        
        if pageType == .Repos {
            paraRepos.page = 1
            searchRepos()
        }else{
            paraUser.page = 1
            searchUser()
        }
        
    }
    
    func svc_footerRefresh() {
        
        if svc_checkSearchKeywordIsNull() {
            return
        }
        
        if pageType == .Repos {
            paraRepos.page += 1
            searchRepos()
        }else{
            paraUser.page += 1
            searchUser()
        }

    }
    
    func svc_combineQueryString() {
        
        if pageType == .Repos {
            paraRepos.keyword = searchBar.text!
            paraRepos.q =  paraRepos.combineQuery()
        }else{
            paraUser.keyword = searchBar.text!
            paraUser.q =  paraUser.combineQuery()
        }
    }
    
    func svc_checkSearchKeywordIsNull() -> Bool {
        
        let keyword:String? = searchBar.text
        
        if ( (keyword == nil) || (keyword?.isEmpty)! ) {
            CPGlobalHelper.sharedInstance.showError("input keyword",view: self.view)
            return true
        }else{
            
        }
        
        return false
        
    }
    
    func svc_searchNow() {
        
        if svc_checkSearchKeywordIsNull(){
            return
        }else{
            svc_startSearchRequest()
        }
        
    }
    
    func svc_startSearchRequest() {
        //1.first combine query string
        svc_combineQueryString()
        //2.requsest for first page
        svc_headerRefresh()
    }
    
    func searchUser() {
        
        MBProgressHUD.showAdded(to: self.view, animated: true)

        Provider.sharedProvider.request(.searchUsers(para:self.paraUser) ) { (result) -> () in
            
            var message = "No data to show"
            
            if(self.paraRepos.page == 1 ) {
                self.tableView.mj_header.endRefreshing()
            }else{
                self.tableView.mj_footer.endRefreshing()
            }
            
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            
            switch result {
            case let .success(response):
                
                do {
                    
                    if (response.statusCode != 200) {
                        let errStr = try response.mapString()
                        print(errStr)
                        return
                    }
                    
                    if let userResult:ObjSearchUserResponse = Mapper<ObjSearchUserResponse>().map(JSONObject: try response.mapJSON() ) {
                        
                        if let total = userResult.totalCount {
                            self.totalItemCount = total
                        }
                        
                        if(self.paraUser.page == 1) {
                            
                            if(self.usersData != nil){
                                self.usersData.removeAll()
                                self.usersData = userResult.items
                            }
                            
                        }else{
                            self.usersData = self.usersData+userResult.items!
                        }
                        
                        self.svc_reloadData()
                        
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
    
    
    func searchRepos() {

        MBProgressHUD.showAdded(to: self.view, animated: true)

        Provider.sharedProvider.request(.searchRepos(para:self.paraRepos) ) { (result) -> () in
            
            var message = "No data to show"
            
            if( self.paraRepos.page == 1 ) {
                self.tableView.mj_header.endRefreshing()
            }else{
                self.tableView.mj_footer.endRefreshing()
            }
            
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            
            switch result {
            case let .success(response):
                
                
                do {
                    if (response.statusCode != 200) {
                        let errStr = try response.mapString()
                        print(errStr)
                        return
                    }
                    
                    if let reposResult:ObjSearchReposResponse = Mapper<ObjSearchReposResponse>().map(JSONObject: try response.mapJSON() ) {
                        
                        if let total = reposResult.totalCount {
                            self.totalItemCount = total
                        }
                        
                        if(self.paraRepos.page == 1) {
                            if(self.reposData != nil){
                                self.reposData.removeAll()
                                self.reposData = reposResult.items
                            }
                            
                        }else{
                            self.reposData = self.reposData+reposResult.items!
                        }
                        
                        self.svc_reloadData()
                        
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
    
    
    func svc_reloadData() {

        if pageType == .Repos {

            if ((reposData == nil) || (reposData.count == 0))  {
                header.isHidden = true
                footer.isHidden = true
                return
            }
            
            if(reposData.count >= totalItemCount){
                header.isHidden = false
                header.isHidden = true
            }else{
                header.isHidden = false
                footer.isHidden = false
            }
            
        }else{
            
            if ((usersData == nil) || (usersData.count == 0))  {
                header.isHidden = true
                footer.isHidden = true
                return
            }
            
            if(usersData.count >= totalItemCount){
                header.isHidden = false
                header.isHidden = true
            }else{
                header.isHidden = false
                footer.isHidden = false
            }
        }
        
        tableView.reloadData()

    }

    
}


extension CPSearchViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        svc_searchNow()
        self.searchBar.endEditing(true)
        self.view.endEditing(true)
        
    }
}


extension CPSearchViewController:CPSearchFilterViewProtcocol {
    
    func didBeginSearch(_ para: [String : Int]) {
        
        let languageIndex:Int = para["Language"]!
        let sortIndex:Int = para["Sort"]!
        
        let languageStr = languageArr![languageIndex]
        
        var lanPara:String?
        
        if languageStr == "All" {
            
        }else{
            lanPara = languageStr
        }
        
        var sortPara:String?
        var orderPara:String?
        

        
        if pageType == .Repos {
            paraRepos.languagePara = lanPara
            if sortIndex == 0 {
                sortPara = ""
                orderPara = "desc"
            }else if(sortIndex == 1){
                sortPara = "stars"
                orderPara = "desc"
            }else if(sortIndex == 2){
                sortPara = "stars"
                orderPara = "asc"
            }else if(sortIndex == 3){
                sortPara = "forks"
                orderPara = "desc"
            }else if(sortIndex == 4){
                sortPara = "forks"
                orderPara = "asc"
            }else if(sortIndex == 5){
                sortPara = "updated"
                orderPara = "desc"
            }else if(sortIndex == 6){
                sortPara = "updated"
                orderPara = "asc"
            }else{
                sortPara = ""
                orderPara = "desc"
            }
            
            paraRepos.sort = sortPara!
            paraRepos.order = orderPara!
            
        }else{
            paraUser.languagePara = lanPara
            if sortIndex == 0 {
                sortPara = ""
                orderPara = "desc"
            }else if(sortIndex == 1){
                sortPara = "followers"
                orderPara = "desc"
            }else if(sortIndex == 2){
                sortPara = "followers"
                orderPara = "asc"
            }else if(sortIndex == 3){
                sortPara = "repositories"
                orderPara = "desc"
            }else if(sortIndex == 4){
                sortPara = "repositories"
                orderPara = "asc"
            }else if(sortIndex == 5){
                sortPara = "joined"
                orderPara = "desc"
            }else if(sortIndex == 6){
                sortPara = "joined"
                orderPara = "asc"
            }else{
                sortPara = ""
                orderPara = "desc"
            }
            
            paraUser.sort = sortPara!
            paraUser.order = orderPara!
        }
        
        svc_searchNow()
    }
    
    
    func showContentView(_ show: Bool) {
        maskView.isHidden = !show
        searchBar.endEditing(true)
    }
    
}

extension CPSearchViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if pageType == .Repos {
            if (reposData != nil){
                return reposData.count
            }
            return 0
        }
        
        if (reposData != nil){
            return usersData.count
        }
        return 0

    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let row = (indexPath as NSIndexPath).row
        var cellId = ""
        
        if pageType == .Repos {
            
            cellId = "CPTrendingRepoCellIdentifier"
            var cell = tableView.dequeueReusableCell(withIdentifier: cellId) as? CPTrendingRepoCell
            if cell == nil {
                cell = (CPTrendingRepoCell.cellFromNibNamed("CPTrendingRepoCell") as! CPTrendingRepoCell)
            }
            
            //handle line in cell
            if row == 0 {
                cell!.topline = true
            }
            if (row == reposData.count-1) {
                cell!.fullline = true
            }else {
                cell!.fullline = false
            }
            
            let repos = self.reposData[row]
            cell!.objRepos = repos
            
            return cell!;
            
        }
        
        cellId = "CPTrendingDeveloperCellIdentifier"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellId) as? CPTrendingDeveloperCell
        if cell == nil {
            cell = (CPTrendingDeveloperCell.cellFromNibNamed("CPTrendingDeveloperCell") as! CPTrendingDeveloperCell)
            
        }
        
        //handle line in cell
        if row == 0 {
            cell!.topline = true
        }
        
        if (row == usersData.count-1) {
            cell!.fullline = true
        }else {
            cell!.fullline = false
        }
        
        let user = self.usersData[row]
        cell!.user = user
        cell!.userNo = row
        
        return cell!;

    }
    
}

extension CPSearchViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if pageType == .Repos {
            return 85
        }
        return 71
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if pageType == .Repos {
            let repos = self.reposData[(indexPath as NSIndexPath).row]
            self.performSegue(withIdentifier: SegueTrendingSearchReposDetailView, sender: repos)
            return
        }
            
        let dev = self.usersData[(indexPath as NSIndexPath).row]
        self.performSegue(withIdentifier: SegueTrendingSearchUserDetailView, sender: dev)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if (segue.identifier == SegueTrendingSearchReposDetailView){

            let reposVC = segue.destination as! CPTrendingRepositoryViewController
            reposVC.hidesBottomBarWhenPushed = true
            
            let repos = sender as? ObjRepos
            if(repos != nil){
                reposVC.repos = repos
            }
            
        }else if(segue.identifier == SegueTrendingSearchUserDetailView){
            
            let devVC = segue.destination as! CPTrendingDeveloperViewController
            devVC.hidesBottomBarWhenPushed = true
            
            let dev = sender as? ObjUser
            if(dev != nil){
                devVC.developer = dev
            }
            
        }
    }

    
}






