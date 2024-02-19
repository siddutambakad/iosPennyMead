
import UIKit
import Kingfisher

class CatalougeListVc: UIViewController, DrawerDelegate, FetchPerticularManagerDelegate, SearchBookManagerDelegate, GetSubDropdownsManagerDelegate, UITextFieldDelegate, FilterItemsBySubCatDelegate {
    
    @IBOutlet var searchField: UITextField!
    @IBOutlet var searchButton: UIButton!
    @IBOutlet var wholeCategoryButton: UIButton!
    @IBOutlet var thisCategoryButton: UIButton!
    @IBOutlet var searchByDesButton: UIButton!
    @IBOutlet var showingBookLabel: UILabel!
    @IBOutlet var showingBookDesLabel: UILabel!
    @IBOutlet var bookCollectionView: UICollectionView!
    @IBOutlet var bookCollectionHeight: NSLayoutConstraint!
    @IBOutlet var backWardButton: UIButton!
    @IBOutlet var firstButton: UIButton!
    @IBOutlet var secondButton: UIButton!
    @IBOutlet var midButton: UIButton!
    @IBOutlet var forwardButton: UIButton!
    @IBOutlet var secondLastButton: UIButton!
    @IBOutlet var lastButton: UIButton!
    @IBOutlet var numberTextField: UITextField!
    @IBOutlet var goButton: UIButton!
    @IBOutlet var errorText: UILabel!
    @IBOutlet var noDataFoundText: UILabel!
    @IBOutlet var paginationView: UIView!
    @IBOutlet var dropdown1: DropDown!
    @IBOutlet var filterDropdown: DropDown!
    @IBOutlet var multipleDropdown: UICollectionView!
    
    var perticularBooks: [PerticularItemsFetch] = []
    var perticularBookData = FetchPerticularManager()
    var searchedBooks = SearchBookManager()
    var totalPage: Int = 0
    var page: Int = 1
    var subCategorySelectedItem: IndexPath?
    var filterData: [FilterData] = [
        FilterData(name: "Newest Items", type: "newlyUpdated"),
        FilterData(name: "Author", type: "author"),
        FilterData(name: "Title", type: "title"),
        FilterData(name: "Price-High", type: "price_high"),
        FilterData(name: "Price-Low", type: "price_low")
    ]
    var isMainCategoryLastApiCalled: Bool = true
    var isdropdownapicalled: Bool = false
    var adesc = 0
    var categoryInfoArray: [(number: String, name: String)]?
    var selectedCategoryName: (name: String, category: String)?
    var dropdownManager = GetSubDropdownsManager()
    var dropdownData: [DropdownGroup] = []
    var selectedCategoryIndex: Int?
    var selectedFilterType: String = "newlyUpdated"
    var selectedFilterIndex: Int = 0
    var selectedFirstDropdownIndex: Int = 0
    var filterItems = FilterItemsBySubCat()
    var selectedReference: String?
    var selectedSubDropdownIndex: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        showIndicator()
        configureUI()
        registerCell1()
        registerCell2()
        paginationStyles()
        configureSearchStyles()
        
        perticularBookData.delegate = self
        
        handleAllThreeApiCalls()
        searchedBooks.delegate = self
        
        self.hideKeyboardWhenTappedAround()
        upDatePerticularBooks()
        
        dropdownManager.delegate = self
        dropdownManager.getSubDropdowns(with: selectedCategoryName?.category ?? "0")
        
        filterItems.delegate = self
        
        firstDropdownSetUp()
        filterDropdownSetUp()
        
        
        self.navigationController?.interactivePopGestureRecognizer!.delegate = self
    }
    override func viewWillAppear(_ animated: Bool) {
        SideMenuManager.shared.configureSideMenu(parentViewController: self)
        SideMenuManager.shared.sideMenuVc.delegate = self
    }
    
    func handleAllThreeApiCalls() {
        print("handleAllThreeApiCalls called")
        if isMainCategoryLastApiCalled {
            perticularBookData.getPerticularCategories(with: selectedCategoryName?.category ?? "0", filterType: selectedFilterType, page: page)
        } else {
            if let searchTerm = searchField.text, !searchTerm.isEmpty {
                adesc = searchByDesButton.isSelected ? 1 : 0
                let categoryNumber = thisCategoryButton.isSelected ? "\(selectedCategoryName?.category ?? "0")" : "0"
                searchedBooks.searchCat(with: searchTerm, adesc: adesc, categoryNumber: Int(categoryNumber)!, sortby: selectedFilterType, page: page)
            }
            filterDropdownSetUp()
        }
    }
    
    
    func firstDropdownSetUp() {
        dropdown1.setPadding(left: 10)
        
        if let categoryInfoArray = categoryInfoArray {
            dropdown1.placeholder = selectedCategoryName?.name
            dropdown1.selectedIndex = selectedCategoryIndex
            let categoryoptions = categoryInfoArray.map{ $0.name }
            dropdown1.optionArray = categoryoptions
        }
        dropdown1.setGradient(startColor: UIColor.MyTheme.brandingColorGradient, endColor: UIColor.MyTheme.brandingColor)
        
        let categoryName = selectedCategoryName?.name ?? ""
        dropdown1.attributedPlaceholder = NSAttributedString(string: "\(categoryName)", attributes: [NSAttributedString.Key.foregroundColor : UIColor.white])
        
        dropdown1.didSelect { [self] (selectedText, index, id) in
            if selectedFirstDropdownIndex != index {
                showIndicator()
                selectedFilterType = "newlyUpdated"
                page = 1
                filterDropdownSetUp()
                isMainCategoryLastApiCalled = true
                if let selectedCategoryInfo = categoryInfoArray?.first(where: { $0.name == selectedText }) {
                    selectedCategoryName = (name: selectedCategoryInfo.name, category: selectedCategoryInfo.number)
                    dropdownManager.getSubDropdowns(with: selectedCategoryName?.category ?? "0")
                    handleAllThreeApiCalls()
                    configureUI()
                }
                selectedFirstDropdownIndex = index
                isdropdownapicalled = false
            } else {
                stopLoading()
            }
        }
    }
    func filterDropdownSetUp() {
        filterDropdown.optionArray = filterData.map({$0.name})
        filterDropdown.text = filterData[0].name
        filterDropdown.checkMarkEnabled = false
        if let defaultIndex = filterData.firstIndex(where: { $0.name == "Newest Items" }) {
            filterDropdown.selectedIndex = defaultIndex
        }
        
        filterDropdown.didSelect { [self] (selectedText, index, id) in
            if selectedFilterIndex != index {
                showIndicator()
                filterDropdown.selectedIndex = index
                selectedFilterIndex = index
                if let selectedFilter = filterData.first(where: { $0.name == selectedText }) {
                    selectedFilterType = selectedFilter.type
                }
                if isdropdownapicalled {
                    filterItems.getFilterItemsBySubCat(category: selectedCategoryName?.category ?? "0", referenceId: selectedReference!, filterType: selectedFilterType, page: 1)
                }else{
                    handleAllThreeApiCalls()
                }
                page=1
            }else {
                stopLoading()
            }
        }
    }
    
    func configureSearchStyles() {
        searchField.layer.borderWidth = 1
        searchField.layer.borderColor = UIColor(named: "borderColor")?.cgColor
        
        searchButton.layer.borderWidth = 1
        searchButton.layer.borderColor = UIColor(named: "borderColor")?.cgColor
        
        wholeCategoryButton.isSelected = true
        wholeCategoryButton.setImage(UIImage(named: "radioOn"), for: .selected)
        wholeCategoryButton.setImage(UIImage(named: "radioOff"), for: .normal)
        
        thisCategoryButton.setImage(UIImage(named: "radioOn"), for: .selected)
        thisCategoryButton.setImage(UIImage(named: "radioOff"), for: .normal)
        
        searchByDesButton.setImage(UIImage(named: "check"), for: .selected)
        searchByDesButton.setImage(UIImage(named: "unCheck"), for: .normal)
    }
    override func viewDidLayoutSubviews() {
        self.updateCollectionViewHeight()
    }
    //MARK: give pagination Styles
    func paginationStyles() {
        firstButton.layer.borderColor = UIColor(named: "borderColor")?.cgColor
        firstButton.layer.borderWidth = 1
        firstButton.layer.cornerRadius = 5
        secondButton.layer.borderWidth = 1
        secondButton.layer.borderColor = UIColor(named: "borderColor")?.cgColor
        secondButton.layer.cornerRadius = 5
        midButton.layer.borderWidth = 1
        midButton.layer.borderColor = UIColor(named: "borderColor")?.cgColor
        midButton.layer.cornerRadius = 5
        secondLastButton.layer.borderWidth = 1
        secondLastButton.layer.borderColor = UIColor(named: "borderColor")?.cgColor
        secondLastButton.layer.cornerRadius = 5
        lastButton.layer.borderWidth = 1
        lastButton.layer.borderColor = UIColor(named: "borderColor")?.cgColor
        lastButton.layer.cornerRadius = 5
        
        backWardButton.layer.borderWidth = 1
        backWardButton.layer.borderColor = UIColor(named: "borderColor")?.cgColor
        backWardButton.layer.cornerRadius = 5
        
        forwardButton.layer.borderWidth = 1
        forwardButton.layer.borderColor = UIColor(named: "borderColor")?.cgColor
        forwardButton.layer.cornerRadius = 5
        
        numberTextField.layer.borderWidth = 1
        numberTextField.layer.borderColor = UIColor(named: "borderColor")?.cgColor
        numberTextField.layer.cornerRadius = 5
        
        paginationView.layer.shadowColor = UIColor.gray.cgColor
        paginationView.layer.cornerRadius = 5
        paginationView.layer.shadowOffset = CGSize(width: 0, height: 3)
        paginationView.layer.shadowRadius = 4.0
        paginationView.layer.shadowOpacity = 0.5
    }
    //MARK: update the heights of the collectionview
    func updateCollectionViewHeight() {
        self.bookCollectionHeight.constant = self.bookCollectionView.contentSize.height
    }
    //MARK: registercell for the bookcollectionview
    func registerCell1() {
        bookCollectionView.delegate = self
        bookCollectionView.dataSource = self
        bookCollectionView.register(UINib(nibName: "CollectibleCvCell", bundle: nil), forCellWithReuseIdentifier: "cellItems")
        let layout = UICollectionViewFlowLayout()
        
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        bookCollectionView.collectionViewLayout = layout
    }
    func registerCell2() {
        multipleDropdown.delegate = self
        multipleDropdown.dataSource = self
        multipleDropdown.register(UINib(nibName: "DropdownCV", bundle: nil), forCellWithReuseIdentifier: "DropdownCV")
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        self.multipleDropdown.collectionViewLayout = layout
    }
    //MARK: Drawer close
    func didPressBacbutton() {
        SideMenuManager.shared.toggleSideMenu(expanded: false)
    }
    //MARK: Drawer open
    @IBAction func onPressDrawerMenu(_ sender: Any) {
        SideMenuManager.shared.toggleSideMenu(expanded: true)
    }
    
    //MARK: firstDropdown
    func configureUI() {
        if let book = selectedCategoryName {
            showingBookLabel.text = book.name
        } else {
            print("selectedBook is nil in CatalougeListVc")
        }
    }
    //MARK: UPDATE Text when searching is done
    func configureText() {
        if let searchTerm = searchField.text, !searchTerm.isEmpty {
            showingBookLabel.text = "Showing results for '\(searchTerm)'"
        } else {
            showingBookLabel.text = selectedCategoryName?.name
        }
    }
    //MARK: searchCat api call
    func didUpdateThePerticularCatSearch(_ perticularCat: [PerticularItemsFetch]) {
        DispatchQueue.main.async { [self] in
            perticularBooks = perticularCat
            upDatePerticularBooks()
            configureText()
            stopLoading()
            bookCollectionView.reloadData()
        }
    }
    //MARK: perticular api call
    func didUpdateThePerticularCat(_ perticularCat: [PerticularItemsFetch]) {
        DispatchQueue.main.async { [self] in
            perticularBooks = perticularCat
            upDatePerticularBooks()
            stopLoading()
            bookCollectionView.reloadData()
        }
    }
    func didRecieveDataForGetSub(response: [PerticularItemsFetch]) {
        DispatchQueue.main.async { [self] in
            perticularBooks = response
            upDatePerticularBooks()
            stopLoading()
            bookCollectionView.reloadData()
        }
    }
    
    //MARK: error for both search and perticular
    func didGetErrors(error: Error, response: HTTPURLResponse?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.stopLoading()
            if let networkError = error as? URLError, networkError.code == .notConnectedToInternet {
                self.showPopUp(title: "No internet connection")
            } else if let httpResponse = response, httpResponse.statusCode == 404 {
                print(httpResponse.statusCode)
            } else {
                // Show popup for other errors
                print("Unexpected error: \(error)")
                self.showPopUp(title: "Something went wrong")
            }
        }
    }
    //MARK: show the popup for any errors
    func showPopUp(title: String) {
        let customPop = CustomPopUp()
        customPop.networkErrorTextTitle = title
        customPop.show()
    }
    //MARK: totalPage
    func didUpdateTotalPages(_ totalPages: Int) {
        DispatchQueue.main.async { [self] in
            self.totalPage = totalPages
            print("===>main response",self.totalPage)
            self.updatePaginationUi(with: self.page, totalPageNo: self.totalPage)
        }
    }
    //MARK: category description
    func didGetTheCatDes(_ categorydescription: [CategoryDescription]) {
        DispatchQueue.main.async { [self] in
            if let firstDescription = categorydescription.first {
                let catDescription = firstDescription.categoryDescription
                showingBookDesLabel.text = catDescription.html2String
            }
        }
    }
    //MARK: show text for no data found
    func upDatePerticularBooks() {
        if perticularBooks.isEmpty {
            noDataFoundText.text = "No Data Found"
            paginationView.isHidden = true
        } else {
            noDataFoundText.text = ""
            paginationView.isHidden = false
        }
        bookCollectionView.reloadData()
    }
    
    //MARK: func for button pagination
    func updatePaginationUi(with page: Int, totalPageNo: Int) {
        DispatchQueue.main.async { [self] in
            self.totalPage = totalPageNo
            print("==>>variable", totalPage)
            print("---->>underpagination func", totalPageNo)
            let halftotalPage = Int(round(Double(totalPageNo) / 2.0))
            if totalPageNo < 6 {
                secondButton.isHidden = totalPageNo == 1 ? true : false
                midButton.isHidden = totalPageNo < 3 ? true : false
                secondLastButton.isHidden = totalPageNo < 4 ? true : false
                lastButton.isHidden = totalPageNo < 5 ? true : false
                firstButton.setTitle("1", for: .normal)
                secondButton.setTitle("2", for: .normal)
                midButton.setTitle("3", for: .normal)
                midButton.isEnabled = true
                secondLastButton.setTitle("4", for: .normal)
                lastButton.setTitle("5", for: .normal)
                firstButton.backgroundColor = page == 1 ? UIColor(named: "borderColor") : .clear
                firstButton.setTitleColor(page == 1 ? .white : UIColor(named: "borderColor"), for: .normal)
                secondButton.backgroundColor = page == 2 ? UIColor(named: "borderColor") : .clear
                secondButton.setTitleColor(page == 2 ? .white : UIColor(named: "borderColor"), for: .normal)
                midButton.backgroundColor = page == 3 ? UIColor(named: "borderColor") : .clear
                midButton.setTitleColor(page == 3 ? .white : UIColor(named: "borderColor"), for: .normal)
                secondLastButton.backgroundColor = page == 4 ? UIColor(named: "borderColor") : .clear
                secondLastButton.setTitleColor(page == 4 ? .white : UIColor(named: "borderColor"), for: .normal)
                lastButton.backgroundColor = page == 5 ? UIColor(named: "borderColor") : .clear
                lastButton.setTitleColor(page == 5 ? .white : UIColor(named: "borderColor"), for: .normal)
            } else if page < halftotalPage {
                // Display pages in the first half
                print("-->halftotalPage", totalPageNo)
                print("-->totalPage", totalPage)
                firstButton.setTitle("\(page)", for: .normal)
                self.page = page
                firstButton.backgroundColor = UIColor(named: "borderColor")
                firstButton.setTitleColor(.white, for: .normal)
                lastButton.backgroundColor = UIColor.clear
                secondButton.setTitle("\(page + 1)", for: .normal)
                midButton.isHidden = false
                midButton.isEnabled = false
                secondLastButton.setTitle("\(totalPageNo - 1)", for: .normal)
                lastButton.setTitle("\(totalPageNo)", for: .normal)
                lastButton.setTitleColor(UIColor(named: "borderColor"), for: .normal)
            } else {
                // Display pages in the second half
                lastButton.setTitle("\(page)", for: .normal)
                lastButton.backgroundColor = UIColor(named: "borderColor")
                lastButton.setTitleColor(.white, for: .normal)
                firstButton.backgroundColor = UIColor.clear
                firstButton.setTitleColor(UIColor(named: "borderColor"), for: .normal)
                secondLastButton.setTitle("\(page - 1)", for: .normal)
                midButton.isHidden = false
                midButton.isEnabled = false
                firstButton.setTitle("1", for: .normal)
                secondButton.setTitle("2", for: .normal)
            }
            backWardButton.isHidden = page == 1 ? true : false
            forwardButton.isHidden = page == totalPageNo ? true : false
        }
    }
    //MARK: Api call for the subdropdowns
    func didGetSubDropdowns(response: [DropdownGroup]) {
        DispatchQueue.main.async { [self] in
            dropdownData = response
            multipleDropdown.reloadData()
        }
    }
    //MARK: oppress search button
    @IBAction func onPressSearchButton(_ sender: UIButton) {
        showIndicator()
        selectedFilterType = "newlyUpdated"
        filterDropdownSetUp()
        isMainCategoryLastApiCalled = false
        if let searchTerm = searchField.text, !searchTerm.isEmpty {
            handleAllThreeApiCalls()
            searchField.text = ""
        }else {
            stopLoading()
            upDatePerticularBooks()
        }
    }
    @IBAction func onPressRadioButtons(_ sender: UIButton) {
        if sender == wholeCategoryButton {
            wholeCategoryButton.isSelected = true
            thisCategoryButton.isSelected = false
        } else if sender == thisCategoryButton {
            wholeCategoryButton.isSelected = false
            thisCategoryButton.isSelected = true
        } else if sender == searchByDesButton {
            searchByDesButton.isSelected = !searchByDesButton.isSelected
        }
    }
    
    @IBAction func onPressNumberButtons(_ sender: UIButton) {
        showIndicator()
        let title = sender.currentTitle
        let intValue = Int(title!) ?? 1
        print(intValue)
        if intValue != page {
            page = intValue
            handleAllThreeApiCalls()
        } else {
            stopLoading()
        }
        
    }
    @IBAction func onPressForwardButton(_ sender: Any) {
        showIndicator()
        if page < totalPage {
            page += 1
            let intValue = page
            page = intValue
            handleAllThreeApiCalls()
        } else {
            stopLoading()
        }
    }
    @IBAction func onPressBackwardButton(_ sender: Any) {
        showIndicator()
        if page > 1 {
            page -= 1
            let intValue = page
            handleAllThreeApiCalls()
        } else {
            stopLoading()
        }
    }
    @IBAction func onPressGoButton(_ sender: UIButton) {
        showIndicator()
        if let text = numberTextField.text, !text.isEmpty {
            if let pageNumber = Int(text), pageNumber >= 1 && pageNumber <= totalPage {
                if pageNumber != page {
                    page = pageNumber
                    handleAllThreeApiCalls()
                    numberTextField.text = ""
                    errorText.text = ""
                } else {
                    errorText.text = "Entered same Page"
                    stopLoading()
                }
            } else {
                errorText.text = "Entered Valid Page"
                stopLoading()
            }
        } else {
            errorText.text = "Please Enter page No"
            stopLoading()
        }
    }
}
//MARK: COllectionView Datasource and Delegate
extension CatalougeListVc: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, DropdownCVDelegate {
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == bookCollectionView {
            return perticularBooks.count
        } else if collectionView == multipleDropdown {
            return dropdownData.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == bookCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellItems", for: indexPath) as! CollectibleCvCell
            let book = perticularBooks[indexPath.item]
            cell.cardAuthor.text = book.author
            cell.cardTitle.text = book.title
            cell.cardDescription.text = book.description
            cell.cardPrice.text = ("£ \(book.price)")
            if let imageUrlString = book.image.first, let imageUrl = URL(string: imageUrlString) {
                cell.cardImage1.kf.setImage(with: imageUrl, placeholder: UIImage(named: "placeholderimg"), options: nil) { result in
                    switch result {
                    case .success(_): break
                    case .failure(let error):
                        print("Error in loading image \(error)")
                    }
                }
            }
            return cell
        } else if collectionView == multipleDropdown {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DropdownCV", for: indexPath) as! DropdownCV
            cell.dropdown.optionArray = dropdownData[indexPath.row].dropdownlist.map({$0.name})
            cell.dropdown.text = dropdownData[indexPath.row].name
            cell.delegate = self
            cell.indexPath = indexPath
            return cell
        }
        return UICollectionViewCell()
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == bookCollectionView {
            let collectionWidth = collectionView.frame.width
            let cellWidth = collectionWidth * 0.84
            return CGSize(width: cellWidth, height: 445)
        } else if collectionView == multipleDropdown {
            return CGSize(width: 200, height: 50)
        }
        return CGSize(width: 0, height: 0)
    }
    func dropdownDidSelectItem(_ selectedText: String, atIndex index: Int, withId id: Int, atIndexPath indexPath: IndexPath) {
        isMainCategoryLastApiCalled = true
        showIndicator()
        let data = dropdownData[indexPath.item].dropdownlist[index]
        if data != nil {
            if selectedReference != data.reference {
                filterItems.getFilterItemsBySubCat(category: selectedCategoryName?.category ?? "0", referenceId: data.reference, filterType: "newlyUpdated", page: 1)
                page = 1
                selectedFilterType = "newlyUpdated"
                filterDropdownSetUp()
            } else {
                stopLoading()
            }
        }
        selectedReference = data.reference
        isdropdownapicalled = true
        updatePaginationUi(with: page, totalPageNo: totalPage)
    }
}
extension CatalougeListVc:UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
