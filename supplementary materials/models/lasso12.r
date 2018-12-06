# lasso with regularisation parameter selected by cv, rolling window. Lag = 12

# cross validation (b/w period T1 n T2)
y <- dat[, targetVar] %>% 
  set_colnames("y")
lambdaChoises <- 10^(seq(0,-3,len=100)) # lambda choices, selection on CV

X <- lag.xts(dat, 1:12+h-1)

predErrLasso <-
  foreach(t = 1:winSize, .combine = "cbind", .inorder = F) %dopar% {
    fitLasso <- glmnet::glmnet(X[(12+h):T1+t-1,],y[(12+h):T1+t-1], # (p+h):T1 instead of 1:T1 bc first p obs's are missing
                       lambda=lambdaChoises, family="gaussian", alpha=1, standardize=F, intercept=F,
                       thresh=1e-15, maxit=1e07) # choose smaller thresh if nr of nonzero coef exceeds winSize
    predLasso <- glmnet::predict.glmnet(fitLasso, zoo::coredata(X[T1+t,]))
    as.numeric((predLasso - as.numeric(y[T1+t]))^2)
  } # endforeach

cvScore <- apply(predErrLasso,1,mean) # MSE for each lambda in cross validation period
optLam <- lambdaChoises[which.min(cvScore)]


LASSOlambda[horizon,targetVar] <- optLam

# evaluatoin

eval <- foreach(t = 1:winSize) %dopar% { 
  fitLasso <- glmnet::glmnet(X[(T1+1):T2+t-1,], y[(T1+1):T2+t-1], lambda = optLam,
                      family = "gaussian", alpha = 1, standardize = F, intercept=F,
                      thresh=1e-15, maxit = 1e07)
  predLasso <- glmnet::predict.glmnet(fitLasso, zoo::coredata(X[T2+t,]))
  err <- as.numeric((predLasso - y[T2+t])^2)
  coefs <- as.numeric(fitLasso$beta)
  list(err, coefs)
}
predErrLasso <- unlist(sapply(eval, function(foo) foo[1]))
coefTracker <- matrix(unlist(sapply(eval, function(foo) foo[2])),
                      nrow=winSize, ncol=ncol(X), byrow=T)

coefTracker[abs(coefTracker) == 0] <- 0
coefTracker[abs(coefTracker) != 0] <- 1 # 1 if coef is selected (non-zero)


msfeLasso <- mean(predErrLasso)

# interpretation


LASSOsparsityRatio[horizon,targetVar] <- mean(coefTracker) # the ratio of non-zero coef
LASSOnonzero[horizon,targetVar] <- sum(coefTracker)/winSize # avg nr of non-zero coef per window

# Notice that the final object `LASSOcoefs` is a list of lists (main list of variables and sub-list of horizons)
if (horizon == 1) {LASSOcoefs[[var]] <- list()} # initialise by setting sub-list so that each main list contains sub-lists
LASSOcoefs[[var]][[horizon]] <- coefTracker
if (horizon == 4) {names(LASSOcoefs[[var]]) <- paste("h", hChoises, sep="")}

MSFEs[[horizon]]["LASSO", targetVar] <- msfeLasso

rm(coefTracker,X, y, cvScore,lambdaChoises,msfeLasso, optLam,predErrLasso,eval)