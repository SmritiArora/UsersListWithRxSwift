

import UIKit
import RxSwift
import RxCocoa

class MainViewController: UIViewController {
    
    fileprivate let bag = DisposeBag()
    
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var tableview: UITableView!
    
    let userViewModelInstance = UserViewModel()
    let userList = BehaviorRelay<[UserDetailModel]>(value: [])
    let filteredList = BehaviorRelay<[UserDetailModel]>(value: [])
    var controller: UserDetailViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userViewModelInstance.callApi()
        controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "UserDetailController") as UserDetailViewController
        bindUI()
    }
    
    func bindUI() {
        
        //Here we subscribe the subject in viewModel to get the value here
        userViewModelInstance.userViewModelObserver.subscribe(onNext: { (value) in
            self.filteredList.accept(value)
            self.userList.accept(value)
        },onError: { error in
            self.errorAlert()
        }).disposed(by: bag)
        
        tableview.tableFooterView = UIView()
        
        //This binds the table datasource with tableview and also connects the cell to it.
        filteredList.bind(to: tableview.rx.items(cellIdentifier: "CellIdentifier", cellType: UserCell.self)) { row, model, cell in
            cell.configureCell(userDetail: model)
        }.disposed(by: bag)
        
        //Replacement to didSelectRowAt() of tableview delegate functions
        tableview.rx.itemSelected.subscribe(onNext: { (indexPath) in
            self.tableview.deselectRow(at: indexPath, animated: true)
            self.controller?.userDetail.accept(self.filteredList.value[indexPath.row])
            self.controller?.userDetail.value.isFavObservable.subscribe(onNext: { _ in
                self.tableview.reloadData()
            }).disposed(by: self.bag)
            self.navigationController?.pushViewController(self.controller ?? UserDetailViewController(), animated: true)
        }).disposed(by: bag)
        
        //Search functionality: Combines the complete data model to search field and binds results to data model binded to the tableview.
        Observable.combineLatest(userList.asObservable(), searchTextField.rx.text, resultSelector: { users, search in
            return users.filter { (user) -> Bool in
                self.filterUserList(userModel: user, searchText: search)
            }
        }).bind(to: filteredList).disposed(by: bag)
    }
    
    //Search function
    func filterUserList(userModel: UserDetailModel, searchText: String?) -> Bool {
        if let search = searchText, !search.isEmpty, !(userModel.userData.first_name?.contains(search) ?? false) {
            return false
        }
        return true
    }
    
    func errorAlert() {
        let alert = UIAlertController(title: "Error", message: "Check your Internet connection and Try Again!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

