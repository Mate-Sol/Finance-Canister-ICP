import Debug "mo:base/Debug";
import Text "mo:base/Text";
import Bool "mo:base/Bool";
import Map "mo:base/HashMap";
import Error "mo:base/Error";
import List "mo:base/List";
import Iter "mo:base/Iter";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Option "mo:base/Option";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Int "mo:base/Int";
import Buffer "mo:base/Buffer";

actor FinanceCanister {
  type Finance = {
    Type : Text;
    FinanceType : Text;
    InvoiceId : Text;
    MongoId : Text;
    FinanceId : Text;
    InvoiceAmount : Text;
    FinanceAmount : Text;
    RemainingAmount : [Remaining];
    RequestedDuration : Text;
    ApprovedAmount : Text;
    DisbursedAmount : Text;
    RepaymentAmount : Text;
    CreationDate : Text;
    Action : Text;
    BankForFinancing : Text;
    RequestBy : Text;
    UserId : Text;
    Currency : Text;
    FinanceDueDate : Int;
    CreditLimit : Text;
    Email : Text;
    MobileNumber : Text;
    TimeStamp : Int;
    ProcessingFee : Text;
    FinanceRate:Text;
    FinanceCost : Text;
    FinanceRequest : Bool;
    Rejected : Bool;
    Default : Bool;
    Approved : Bool;
    PaymentDisbursed : Bool;
    Repayment : Bool;
    RejectedRemarks : Text;
    DefaultRemarks : Text;
    ApprovedRemarks : Text;
    PaymentDisbursedRemarks : Text;
    RepaymentRemarks : Text;
    FinancingScore : Text;
    TxnHash : Text;
  };
  type Remaining = {
    Amount : Text;
    Status : Text;
  };

  type QueryResult = {
    Key : Text;
    Record : ?Finance;
  };

  type QueryHistory = {
    Record : Text;
  };
  private stable var mapEntries : [(Text, Finance)] = [];
  private var map : Map.HashMap<Text, Finance> = Map.HashMap<Text, Finance>(0, Text.equal, Text.hash);
  private stable var historyEntries : [(Text, [Finance])] = [];
  var history = Map.HashMap<Text, Buffer.Buffer<Finance>>(0, Text.equal, Text.hash);

  public func CreateFinanceInvoice(
    invoiceId : Text,
    mongoid : Text,
    financeid : Text,
    email : Text,
    mobileNo : Text,
    userid : Text,
    financetype : Text,
    requestedby : Text,
    creationdate : Text,
    action : Text,
    requestedduration : Text,
    bankforfinance : Text,
    financeamount : Text,
    invoiceamount : Text,
    financescore : Text,
    processingfee : Text,
    creditlimit : Text,
    amount : Text,
    currency : Text,
    txnHash : Text,
    Times:Int
  ) : async Text {
    switch (map.get(financeid)) {
      case (null) {
        let array = Buffer.fromArray<Remaining>([]);
        array.add({ Amount = amount; Status = action });
        let finance : Finance = {
          Type = "Finance";
          InvoiceId = invoiceId;
          MongoId = mongoid;
          FinanceId = financeid;
          FinanceType = financetype;
          InvoiceAmount = invoiceamount;
          FinanceAmount = financeamount;
          RemainingAmount = Buffer.toArray<Remaining>(array);
          RequestedDuration = requestedduration;
          ApprovedAmount = "";
          DisbursedAmount = "";
          RepaymentAmount = "";
          CreationDate = creationdate;
          Action = action;
          BankForFinancing = bankforfinance;
          RequestBy = requestedby;
          UserId = userid;
          FinanceDueDate = 0;
          CreditLimit = "";
          Email = "";
          MobileNumber = "";
          TimeStamp = Times;
          ProcessingFee = processingfee;
          FinanceCost = "";
          FinanceRequest = true;
          Rejected = false;
          Approved = false;
          PaymentDisbursed = false;
          Repayment = false;
          Default = false;
          DefaultRemarks = "";
          RejectedRemarks = "";
          Currency = currency;
          ApprovedRemarks = "";
          PaymentDisbursedRemarks = "";
          RepaymentRemarks = "";
          FinancingScore = "";
          FinanceRate = "";
          TxnHash = txnHash;
        };
        map.put(financeid, finance);
        var a = Buffer.Buffer<Finance>(0);
        a.add(finance);
        history.put(financeid, a);
        return "Finance invoice created";
      };

      case (?value) {
        return "Finance invoice already exists";
      };
    };
  };

  public func ApproveFinance(financeId : Text, action : Text, financeRate : Text, approveAmount : Text, approveRemarks : Text, amount : Text, txnHash : Text, Times:Int) : async Text {
    switch (map.get(financeId)) {
      case (?value) {
        if (value.FinanceRequest == true and value.Approved == false and value.PaymentDisbursed == false and value.Repayment == false and value.Rejected == false) {
          let array = Buffer.fromArray<Remaining>(value.RemainingAmount);
          let updatedFinance = {
            value with
            Approved = true;
            ApproveAmount = approveAmount;
            FinanceRate = financeRate;
            TimeStamp = Times;
            Action = action;
            ApproveRemarks = approveRemarks;
            RemainingAmount = Buffer.toArray<Remaining>(array);
            TxnHash = txnHash;
          };
          let updatedMap = map.put(financeId, updatedFinance);
          switch (history.get(financeId)) {
            case (?x) {
              x.add(updatedFinance);
              let res = history.put(financeId, x);
            };
            case (null) {};
          };
          return "Finance approved";
        } else {
          return Text.concat("Request failed, current invoice status = ", value.Action);
        };
      };
      case (null) {
        return "Finance not found!";
      };
    };
  };

  public func DisburseFinance(financeId : Text, action : Text, disbursmentAmount : Text, disbursementRemarks : Text, amount : Text, dueDate : Int, txnHash : Text, Times:Int) : async Text {
    switch (map.get(financeId)) {
      case (?value) {
        if (value.FinanceRequest == true and value.Approved == true and value.PaymentDisbursed == false and value.Repayment == false and value.Rejected == false) {
          let array = Buffer.fromArray<Remaining>(value.RemainingAmount);
          let updatedFinance = {
            value with
            TimeStamp = Times;
            Action = action;
            PaymentDisbursed = true;
            FinanceDueDate = dueDate;
            DisbursmentAmount = disbursmentAmount;
            PaymentDisbursedRemarks = disbursementRemarks;
            RemainingAmount = Buffer.toArray<Remaining>(array);
            TxnHash = txnHash;
          };
          let updatedMap = map.put(financeId, updatedFinance);
          switch (history.get(financeId)) {
            case (?x) {
              x.add(updatedFinance);
              let res = history.put(financeId, x);
            };
            case (null) {};
          };
          return "Finance disbursed";
        } else {
          return Text.concat("Request failed, current invoice status = ", value.Action);
        };
      };
      case (null) {
        return "Finance not found!";
      };
    };
  };

  public func RepaymentFinance(financeid : Text, action : Text, repaymentamount : Text, repaymentremarks : Text, financecost : Text, amount : Text, txnHash : Text, Times:Int) : async Text {
    switch (map.get(financeid)) {
      case (?value) {
        if (value.FinanceRequest == true and value.Approved == true and value.PaymentDisbursed == true and value.Repayment == false and value.Rejected == false) {
          let array = Buffer.fromArray<Remaining>(value.RemainingAmount);

          let updatedFinance = {
            value with
            Repayment = true;
            RepaymentAmount = repaymentamount;
            RepaymentRemarks = repaymentremarks;
            FinanceCost = financecost;
            TimeStamp = Times;
            Action = action;
            RemainingAmount = Buffer.toArray<Remaining>(array);

            TxnHash = txnHash;
          };
          let updatedMap = map.put(financeid, updatedFinance);
          switch (history.get(financeid)) {
            case (?x) {
              x.add(updatedFinance);
              let res = history.put(financeid, x);
            };
            case (null) {};
          };
          return "Finance Repayment";
        } else {
          return Text.concat("Request failed, current invoice status = ", value.Action);
        };
      };
      case (null) {
        return "Finance not found!";
      };
    };
  };

  public func RejectFinance(financeId : Text, rejectremarks : Text, action : Text, txnHash : Text, Times:Int) : async Text {
    switch (map.get(financeId)) {
      case (?value) {
        if (value.FinanceRequest == true and value.Approved == false and value.PaymentDisbursed == false and value.Repayment == false and value.Rejected == false) {
          let updatedFinance = {
            value with
            Rejected = true;
            RejectedRemarks = rejectremarks;
            TimeStamp = Times;
            Action = action;
            TxnHash = txnHash;
          };
          let updatedMap = map.put(financeId, updatedFinance);
          switch (history.get(financeId)) {
            case (?x) {
              x.add(updatedFinance);
              let res = history.put(financeId, x);
            };
            case (null) {};
          };
          return "Finance Reject";
        } else {
          return Text.concat("Request failed, current invoice status = ", value.Action);
        };
      };
      case (null) {
        return "Finance not found!";
      };
    };
  };

  public func EnableDefaultFinance(financeId : Text, action : Text, defaultRemarks : Text, txnHash : Text, Times:Int) : async Text {
    switch (map.get(financeId)) {
      case (?value) {
        if (value.FinanceRequest == true and value.Approved == true and value.PaymentDisbursed == true and value.Repayment == false and value.Rejected == false and value.Default == false and Int.greater(Time.now(), value.FinanceDueDate)) {
          let updatedFinance = {
            value with
            TimeStamp = Times;
            Default = true;
            Action = action;
            DefaultRemarks = defaultRemarks;
            TxnHash = txnHash;
          };
          let updatedMap = map.put(financeId, updatedFinance);
          switch (history.get(financeId)) {
            case (?x) {
              x.add(updatedFinance);
              let res = history.put(financeId, x);
            };
            case (null) {};
          };
          return "Finance request is defaulted due to pendding dues of Finance";
        } else {
          return Text.concat("Request failed, current invoice status = ", value.Action);
        };
      };
      case (null) {
        return "Finance not found!";
      };
    };
  };

  // public func FinanceDelete(financeId : Text, action : Text, financeRate : Text, approveAmount : Text, approveRemarks : Text, amount : Text, txnHash : Text) : async Text {
  //   switch (map.get(financeId)) {
  //     case (?value) {
  //       if (value.FinanceRequest == false and value.Approved == false and value.PaymentDisbursed == false and value.Repayment == false and value.Rejected == false) {
  //         let updatedFinance = {
  //           value with
  //           TimeStamp = Time.now();
  //           Action = action;
  //           FinanceRate = financeRate;
  //           ApproveAmount = approveAmount;
  //           ApproveRemarks = approveRemarks;
  //           TxnHash = txnHash;
  //         };
  //         let updatedMap = map.put(financeId, updatedFinance);
  //         switch (history.get(financeId)) {
  //           case (?x) {
  //             x.add(updatedFinance);
  //             let res = history.put(financeId, x);
  //           };
  //           case (null) {};
  //         };
  //         return "Finance approved";
  //       } else {
  //         return Text.concat("Request failed, current invoice status = ", value.Action);
  //       };
  //     };
  //     case (null) {
  //       return "Finance not found!";
  //     };
  //   };
  // };

  public func DisableDefaultFinance(financeId : Text, action : Text, defaultRemarks : Text, txnHash : Text, Times:Int) : async Text {
    switch (map.get(financeId)) {
      case (?value) {
        if (value.FinanceRequest == true and value.Approved == true and value.PaymentDisbursed == true and value.Repayment == true and value.Default == true and value.Rejected == false) {
          let updatedFinance = {
            value with
            TimeStamp = Times;
            Action = action;
            Default = false;
            DefaultRemarks = defaultRemarks;
            TxnHash = txnHash;
          };
          let updatedMap = map.put(financeId, updatedFinance);
          switch (history.get(financeId)) {
            case (?x) {
              x.add(updatedFinance);
              let res = history.put(financeId, x);
            };
            case (null) {};
          };
          return "Finance defalt check is disabled all pending dues cleared!";
        } else {
          return Text.concat(Text.concat("Request failed, current invoice status = ", value.Action), Text.concat(" and repayment staus = ", Bool.toText(value.Repayment)));
        };
      };
      case (null) {
        return "Finance not found!";
      };
    };
  };

  public func ExtendFinanceDuedate(financeId : Text, action : Text, dueDate : Int, txnHash : Text, Times:Int) : async Text {
    switch (map.get(financeId)) {
      case (?value) {
        if (Int.greater(dueDate, value.FinanceDueDate)  and value.Rejected != true) {
          let updatedFinance = {
            value with
            TimeStamp = Times;
            Action = action;
            FinanceDueDate = dueDate;
            TxnHash = txnHash;
          };
          let updatedMap = map.put(financeId, updatedFinance);
          switch (history.get(financeId)) {
            case (?x) {
              x.add(updatedFinance);
              let res = history.put(financeId, x);
            };
            case (null) {};
          };
          return "Finance dueDate extended";
        } else if (value.Rejected == true) {

          return Text.concat("Request failed, current invoice status = ", value.Action);

        } else  {

          return "Request failed finance duedate not expired";

        }
      };
      case (null) {
        return "Finance not found!";
      };
    };
  };

  public query func QueryAllInvoicesFinance() : async [(Text, Finance)] {
    var tempArray : [(Text, Finance)] = [];
    tempArray := Iter.toArray(map.entries());

    return tempArray;
  };

  public query func QueryInvoice(id : Text) : async ?Finance {
    map.get(id);
  };

  public query func GetInvoiceFinanceHistory(mongoId : Text) : async [Finance] {
    switch (history.get(mongoId)) {
      case (?x) {
        return Buffer.toArray<Finance>(x);
      };
      case (null) {
        return [];
      };
    };

  };

  system func preupgrade() {
    mapEntries := Iter.toArray(map.entries());
    let Entries = Iter.toArray(history.entries());
    var data = Map.HashMap<Text, [Finance]>(0, Text.equal, Text.hash);

    for (x in Iter.fromArray(Entries)) {
      data.put(x.0, Buffer.toArray<Finance>(x.1));
    };
    historyEntries := Iter.toArray(data.entries());

  };
  system func postupgrade() {
    map := HashMap.fromIter<Text, Finance>(mapEntries.vals(), 1, Text.equal, Text.hash);
    let his = HashMap.fromIter<Text, [Finance]>(historyEntries.vals(), 1, Text.equal, Text.hash);
    let Entries = Iter.toArray(his.entries());
    for (x in Iter.fromArray(Entries)) {
      history.put(x.0, Buffer.fromArray<Finance>(x.1));
    };

  };
};
